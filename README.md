glr — glrenderer
===

glrenderer — Delphi 2D game development framework (OpenGL, Bass, Box2D) for Windows platform. 

**Status: frozen due to author's PL preferences changed**

Delphi 2007 or higher is supported. Delphi 7 **is not** supported due to operator overloading used in Math unit.

###Features###

**Main**
* No VCL, win32 api
* DLL, export interfaces

**Graphics 2D**
* Scene graph
* Sprites (position, scale, rotation, textures, color tint)
* Blending
* Bitmap fonts with runtime generation from .otf and .ttf files
* Pivot points support including custom position
* Texture atlas support
* BMP 24/32, TGA 24/32 support (no PNG, sorry)

**Graphics 3D**
* Almost removed

**GUI**
* Selfmade simple GUI-system with:
* Buttons and TextButtons
* Checkboxes
* Sliders

**Sound**
* Little wrapper for Bass library

**Physics — Box2D**
* "box2d-delphi" project support
* Wrapper for World class
* Functions for synchronise render and physic objects
* Functions for easy physic objects create using render objects
* Physic scale support (physics is calculated in other units, not pixels)

**Other**
* Math unit with vectors, matrices and some other things
* Tween system
* Cheetah Texture Atlas support
* Async input

###Known ussues and *facepalms*###
* No documentation and lack of comments in source code
* Bitmap font generation uses fixed texture size due to laziness
* Text has not alignment support
* Particles was under development
