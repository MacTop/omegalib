/**************************************************************************************************
 * THE OMEGA LIB PROJECT
 *-------------------------------------------------------------------------------------------------
 * Copyright 2010-2013		Electronic Visualization Laboratory, University of Illinois at Chicago
 * Authors:										
 *  Alessandro Febretti		febret@gmail.com
 *-------------------------------------------------------------------------------------------------
 * Copyright (c) 2010-2013, Electronic Visualization Laboratory, University of Illinois at Chicago
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without modification, are permitted 
 * provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, this list of conditions 
 * and the following disclaimer. Redistributions in binary form must reproduce the above copyright 
 * notice, this list of conditions and the following disclaimer in the documentation and/or other 
 * materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR 
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE  GOODS OR SERVICES; LOSS OF 
 * USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *************************************************************************************************/
#include "omega/PixelData.h"
#include "omegaOsg/OsgModule.h"
#include "omegaOsg/OsgRenderPass.h"
#include "omegaOsg/OsgSceneObject.h"

#include <osgUtil/Optimizer>
#include <osgUtil/UpdateVisitor>
#include <osgDB/ReadFile>
#include <osgDB/Registry>
#include <osgDB/DatabasePager>
#include <osg/Node>
#include <osg/FrameStamp>

#include "omegaOsg/ReaderFreeImage.h"
#ifdef OMEGAOSG_USE_INVENTOR
#include "Inventor/ReaderWriterIV.h"
#endif
#ifdef OMEGAOSG_USE_FBX
#include "fbx/ReaderWriterFBX.h"
#endif

using namespace omegaOsg;

OsgModule* OsgModule::mysInstance = NULL;
//bool OsgModule::mysAmbientOverrideHack = true;

///////////////////////////////////////////////////////////////////////////////////////////////////
osg::Image* OsgModule::pixelDataToOsg(PixelData* img)
{
	//bool leaveMemoryAlone = false;

	//// If the image delete is disabled, the image does not own the pixel buffer. Tell the
	//// same to osg::Image. Otherwise, pass the buffer ownership to osg::Image.
	//if(img->isDeleteDisabled())
	//{
	//	leaveMemoryAlone = true;
	//}
	//else
	//{
	//	img->setDeleteDisabled(true);
	//}
	// CHANGE: osg::Image never gets ownership of pixel data. We do not care
	// if it gets released. The PixelData object manages the buffer lifetime.
	bool leaveMemoryAlone = true;

	int s = img->getWidth();
    int t = img->getHeight();
    int r = 1;

    int internalFormat = img->getBpp() / 8;

    unsigned int pixelFormat =
        internalFormat == 1 ? GL_LUMINANCE :
    internalFormat == 2 ? GL_LUMINANCE_ALPHA :
    internalFormat == 3 ? GL_RGB :
    internalFormat == 4 ? GL_RGBA : (GLenum)-1;

    unsigned int dataType = GL_UNSIGNED_BYTE;

    osg::Image* pOsgImage = new osg::Image;
    pOsgImage->setImage(s,t,r,
        internalFormat,
        pixelFormat,
        dataType,
		img->map(),
		leaveMemoryAlone ? osg::Image::NO_DELETE : osg::Image::USE_MALLOC_FREE);

	img->unmap();
	return pOsgImage;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
OsgModule* OsgModule::instance() 
{ 
	if(mysInstance == NULL)
	{
		mysInstance = new OsgModule();
		ModuleServices::addModule(mysInstance);
		mysInstance->doInitialize(Engine::instance());
	}
	return mysInstance; 
}

///////////////////////////////////////////////////////////////////////////////////////////////////
OsgModule::OsgModule():
	EngineModule("OsgModule"),
		myDepthPartitionMode(DepthPartitionOff),
		myDepthPartitionZ(1000)
{
    mysInstance = this;

	myAutoNearFar = false;

    myRootNode = NULL;
    //myRootSceneObject = NULL;

	myDatabasePager = osgDB::DatabasePager::create();

    myFrameStamp = new osg::FrameStamp;
    myUpdateVisitor = new osgUtil::UpdateVisitor;
    myUpdateVisitor->setFrameStamp( myFrameStamp );
	myUpdateVisitor->setDatabaseRequestHandler(myDatabasePager);

    osgDB::Registry::instance()->addReaderWriter(new ReaderFreeImage());
#ifdef OMEGAOSG_USE_FBX
	osgDB::Registry::instance()->addReaderWriter(new ReaderWriterFBX());
#endif
	//osgDB::Registry::instance()->addReaderWriter(new ReaderWriterIV());
}

///////////////////////////////////////////////////////////////////////////////////////////////////
OsgModule::~OsgModule()
{
	omsg("~OsgModule");
	mysInstance = NULL;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
void OsgModule::initialize()
{
}

///////////////////////////////////////////////////////////////////////////////////////////////////
void OsgModule::dispose()
{
	getEngine()->removeRenderPass("OsgRenderPass");
}

///////////////////////////////////////////////////////////////////////////////////////////////////
void OsgModule::initializeRenderer(Renderer* r)
{
	OsgRenderPass* osgrp = new OsgRenderPass(r, "OsgRenderPass");
	osgrp->setUserData(this);
	r->addRenderPass(osgrp);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
void OsgModule::setRootNode(osg::Node* value) 
{ 
    myRootNode = value; 
}

///////////////////////////////////////////////////////////////////////////////////////////////////
void OsgModule::update(const UpdateContext& context)
{
    myFrameStamp->setFrameNumber(context.frameNum);
    myFrameStamp->setReferenceTime(context.time);
    myFrameStamp->setSimulationTime(context.time);

    myUpdateVisitor->reset();
    myUpdateVisitor->setFrameStamp(myFrameStamp);
    myUpdateVisitor->setTraversalNumber(context.frameNum);
    if(myRootNode != NULL)
    {
        myRootNode->accept(*myUpdateVisitor);
    }
	myDatabasePager->updateSceneGraph(*myFrameStamp);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
bool OsgModule::handleCommand(const String& command)
{
	Vector<String> args = StringUtils::split(command);
	if(args[0] == "?")
	{
		// ?: print help
		omsg("OsgModule");
		omsg("\t autonearfar [on|off] - (experimental) toggle auto near far Z on or off");
		omsg("\t depthpart [on <value>|off|near|far] - set the depth partition mode and Z threshold");
	}
	else if(args[0] == "autonearfar")
	{
		if(args.size() > 1)
		{
			if(args[1] == "on") setAutoNearFar(true);
			else if(args[1] == "off") setAutoNearFar(false);
		}
		ofmsg("OsgModule: autoNearFar = %1%", %getAutoNearFar());
		// Mark command as handled
		return true;
	}
	else if(args[0] == "depthpart")
	{
		if(args.size() > 1)
		{
			if(args[1] == "on" && args.size() > 2)
			{
				float z = boost::lexical_cast<float>(args[2]);
				myDepthPartitionMode = DepthPartitionOn;
				myDepthPartitionZ = z;
			}
			else if(args[1] == "off")
			{
				myDepthPartitionMode = DepthPartitionOff;
			}
			else if(args[1] == "near")
			{
				myDepthPartitionMode = DepthPartitionNearOnly;
			}
			else if(args[1] == "far")
			{
				myDepthPartitionMode = DepthPartitionFarOnly;
			}
			else
			{
				ofwarn("OsgModule::handleCommand: unknown depth partition mode %1%", %command);
			}
		}
	}
	return false;
}
