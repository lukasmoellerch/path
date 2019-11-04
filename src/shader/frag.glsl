//
//  main.c
//  raytracer
//
//  Created by Lukas Möller on 20.07.19.
//  Copyright © 2019 Lukas Möller. All rights reserved.
//
#define f float
#ifndef GL_ES
#include<iostream>
#include<fstream>
#include<algorithm>
#include<cmath>
#include<thread>
#include<cstring>
#else
precision highp float;
uniform vec2 resolution;
uniform f time;
uniform int samples;
uniform f random;
uniform sampler2D texture;

#define M_PI 3.1415926535897932384626433832795
#define INFINITY 99999999999.
#define static
#define inline
#endif

#ifndef GL_ES
struct vec3{
    f x;
    f y;
    f z;
    vec3(f x,f y,f z):x(x),y(y),z(z){
    }
};
struct vec2{
    f x;
    f y;
    vec2(f x,f y):x(x),y(y){
    }
};

struct Color{
    f r;
    f g;
    f b;
    Color(f r,f g,f b):r(r),g(g),b(b){
    }
};
#else
#define Color vec3
#endif
#ifndef GL_ES
struct Image{
    float*data;
    int width;
    int height;
};
#endif
struct Camera{
    vec3 position;
    vec3 direction;
    f angle;
    vec3 up;
    vec3 right;
    #ifndef GL_ES
    Camera(vec3 position,vec3 direction,f angle,vec3 up,vec3 right):position(position),direction(direction),angle(angle),up(up),right(right){
        
    }
    #endif
};
#ifndef GL_ES
enum MeshType{SPHERE=0,PLANE};
#define MeshTypeSphere MeshType::SPHERE
#define MeshTypePlane MeshType::PLANE
#else
#define MeshType int
#define MeshTypeSphere 0
#define MeshTypePlane 1
#endif

struct SphereMesh{
    vec3 center;
    f radius;
    #ifndef GL_ES
    SphereMesh(vec3 center,f radius):center(center),radius(radius){
    }
    #endif
};
struct PlaneMesh{
    vec3 center;
    vec3 normal;
    #ifndef GL_ES
    PlaneMesh(vec3 center,vec3 normal):center(center),normal(normal){
    }
    #endif
};
struct Mesh{
    MeshType tag;
    #ifndef GL_ES
    union{
        SphereMesh sphere;
        PlaneMesh plane;
    };
    #else
    SphereMesh sphere;
    PlaneMesh plane;
    #endif
    #ifndef GL_ES
    Mesh(SphereMesh sphere):tag(MeshTypeSphere),sphere(sphere){
    }
    Mesh(PlaneMesh plane):tag(MeshTypePlane),plane(plane){
    }
    #endif
};
#ifndef GL_ES
Mesh createSphere(vec3 sphere_center,f sphere_radius){
    return Mesh(SphereMesh(sphere_center,sphere_radius));
}
Mesh createPlane(vec3 plane_center,vec3 plane_normal){
    return Mesh(PlaneMesh(plane_center,plane_normal));
}
#else
Mesh createSphere(vec3 sphere_center,f sphere_radius){
    return Mesh(MeshTypeSphere,SphereMesh(sphere_center,sphere_radius),PlaneMesh(vec3(0,0,0),vec3(0,0,0)));
}
Mesh createPlane(vec3 plane_center,vec3 plane_normal){
    return Mesh(MeshTypePlane,SphereMesh(vec3(0,0,0),0.),PlaneMesh(plane_center,plane_normal));
}
#endif
struct Material{
    Color color;
    f emission;
    f roughness;
    f reflectivity;
    #ifndef GL_ES
    Material(Color color,f emission,f roughness,f reflectivity):color(color),emission(emission),roughness(roughness),reflectivity(reflectivity){
    }
    #endif
};
struct Object{
    Mesh mesh;
    Material material;
    #ifndef GL_ES
    Object(Mesh mesh,Material material):mesh(mesh),material(material){
    }
    #endif
};
#define numObjects 5
struct World{
    Camera camera;
    #ifndef GL_ES
    Object*objects;
    #endif
    #ifndef GL_ES
    World(Camera a,Object b[numObjects]):camera(a){
        objects=(Object*)malloc(sizeof(Object)*numObjects);
        std::memcpy(objects,b,sizeof(Object)*numObjects);
    }
    #endif
};
struct Ray{
    vec3 origin;
    vec3 direction;// normalized
    #ifndef GL_ES
    Ray(vec3 origin,vec3 direction):origin(origin),direction(direction){
        
    }
    #endif
};

static const vec3 null=vec3(0,0,0);
static const Color sky=Color(0,0,0);
static const Color red=Color(1,0,0);
static const Color blue=Color(0,0,1);
static const Color green=Color(0,1,0);
static const Color white=Color(1,1,1);
static const Color purple=Color(.8,.1,.8);
static const Color bluegreen=Color(.1,.5,.9);
static const Color black=Color(0,0,0);
static inline Color multiplyColor(Color a,Color b){
    #ifndef GL_ES
    Color color=Color(std::min<f>(1.,a.r*b.r),std::min<f>(1.,a.g*b.g),std::min<f>(1.,a.b*b.b));
    return color;
    #else
    return a*b;
    #endif
}
static inline Color normalizedVectorColor(vec3 vec){
    f r=((vec.x+1.)*.5);
    f g=((vec.y+1.)*.5);
    f b=((vec.z+1.)*.5);
    return Color(r,g,b);
}
#ifndef GL_ES
static inline Image createImage(int width,int height){
    Image image;
    image.height=height;
    image.width=width;
    image.data=(float*)(malloc(width*height*4*sizeof(float)));
    return image;
}
static inline void freeImage(Image image){
    free(image.data);
}
static inline void saveImage(Image image,const char*location){
    int numberOfBytes=sizeof(float)*image.width*image.height*3;
    char*imageData=(char*)malloc(numberOfBytes);
    for(int i=0;i<image.width*image.height;i++){
        imageData[3*i]=(unsigned char)(image.data[4*i]*255.);
        imageData[3*i+1]=(unsigned char)(image.data[4*i+1]*255.);
        imageData[3*i+2]=(unsigned char)(image.data[4*i+2]*255.);
    }
    std::ofstream file(location,std::ios::out|std::ios::binary);
    if(!file){
        return;
    }
    file<<((char)80)<<((char)54)<<((char)32)<<image.width<<((char)32)<<image.height<<((char)32)<<((char)50)<<((char)53)<<((char)53)<<((char)32);
    file.write((char*)imageData,numberOfBytes);
    file.close();
}
static inline void imageSetPixel(Image image,int x,int y,Color color){
    int location=4*(x+((image.width-y-1)*image.width));
    image.data[location]=std::min<f>(color.r,1);
    image.data[location+1]=std::min<f>(color.g,1);
    image.data[location+2]=std::min<f>(color.b,1);
    image.data[location+3]=1;
}
static inline Color imageGetPixel(Image image,int x,int y){
    int location=4*(x+((image.width-y-1)*image.width));
    return Color(image.data[location],image.data[location+1],image.data[location+2]);
}
static inline f length(vec3 v){
    return std::sqrt(v.x*v.x+v.y*v.y+v.z*v.z);
}
static inline vec3 normalize(vec3 v){
    f l=length(v);
    return vec3(v.x/l,v.y/l,v.z/l);
}
static inline vec3 operator-(vec3 a,vec3 b){
    return vec3(a.x-b.x,a.y-b.y,a.z-b.z);
}
static inline vec3 operator+(vec3 a,vec3 b){
    return vec3(a.x+b.x,a.y+b.y,a.z+b.z);
}
static inline vec3 operator-(vec3 a){
    return vec3(-a.x,-a.y,-a.z);
}
static inline f dot(vec3 a,vec3 b){
    return a.x*b.x+a.y*b.y+a.z*b.z;
}
static inline vec3 operator*(vec3 a,f factor){
    return vec3(a.x*factor,a.y*factor,a.z*factor);
}
static inline vec3 cross(vec3 a,vec3 b){
    f x=a.y*b.z-a.z*b.y;
    f y=a.z*b.x-a.x*b.z;
    f z=a.x*b.y-a.y*b.x;
    return vec3(x,y,z);
}
static inline vec2 operator+(vec2 a,vec2 b){
    return vec2(a.x+b.x,a.y+b.y);
}
#endif
static inline vec3 reflectIncidentNormal(vec3 incident,vec3 normal){
    return normalize(incident-((normal*2.)*dot(incident,normal)));
}
static inline Camera createCameraLookingFromTo(vec3 from,vec3 to){
    vec3 up=vec3(0,1,0);
    vec3 position=from;
    f angle=M_PI*(40./2.)/180.;
    vec3 direction=normalize(to-from);
    vec3 right=cross(up,direction);
    
    Camera camera=Camera(position,direction,angle,up,right);
    
    return camera;
}
static inline Object getObject(int index,f time){
    if(index==0){
        return Object(createPlane(vec3(0,-.5,0),vec3(0,1,0)),Material(white,0.,.5,0.));
    }
    if(index==1){
        return Object(createSphere(vec3(-4.+6.*cos(time/20.),2.+6.*abs(sin(time/20.)),2.3),2.5),Material(Color(1.,.8,.8),1.,0.,0.));
    }
    if(index==2){
        return Object(createSphere(vec3(cos(time),0.,sin(time)),sin(time)),Material(white,0.,0.,1.));
    }
    if(index==3){
        return Object(createSphere(vec3(cos(time+2.),0.,sin(time+2.)),.5),Material(green,0.,0.,1.));
    }
    return Object(createSphere(vec3(cos(time+4.5),0.,sin(time+4.5)),.5),Material(red,0.,.5,0.));
}
static inline World createWorld(){
    vec3 cameraPosition=vec3(-9.,6.,-3.);
    vec3 cameraTargetPosition=vec3(0.,0.,0.);
    Camera camera=createCameraLookingFromTo(cameraPosition,cameraTargetPosition);
    #ifndef GL_ES
    Object objects[]={
        getObject(0),
        getObject(1),
        getObject(2),
        getObject(3),
        getObject(4)
    };
    Object*objectsPtr=(Object*)malloc(sizeof(objects));
    std::memcpy(objectsPtr,&objects,sizeof(objects));
    
    World world=World(camera,objectsPtr);
    #else
    World world=World(camera);
    #endif
    return world;
}
#ifndef GL_ES
static inline void freeWorld(World world){
    free(world.objects);
}
#endif
// INFINITY represents no intersection
static f intersect(Mesh mesh,Ray ray){
    if(mesh.tag==MeshTypeSphere){
        vec3 L=mesh.sphere.center-ray.origin;
        f tca=dot(L,ray.direction);
        f d2=dot(L,L)-tca*tca;
        if(d2>mesh.sphere.radius){
            return INFINITY;
        }
        f thc=sqrt(mesh.sphere.radius-d2);
        f t0=tca-thc;
        f t1=tca+thc;
        if(t0>t1){
            f temp=t0;
            t0=t1;
            t1=temp;
        }
        if(t0<0.){
            t0=t1;
            if(t0<0.){
                return INFINITY;
            }
        }
        f t=t0;
        return t;
    }else if(mesh.tag==MeshTypePlane){
        f denom=dot(mesh.plane.normal,ray.direction);
        if(abs(denom)>.000001){
            f t=dot(mesh.plane.center-ray.origin,mesh.plane.normal)/denom;
            if(t>=0.){
                return t;
            }
        }
        return INFINITY;
    }
    return INFINITY;
}

static inline vec3 normalVectorOfMeshAtPoint(Mesh mesh,vec3 point){
    if(mesh.tag==MeshTypeSphere){
        return normalize(point-mesh.sphere.center);
    }else if(mesh.tag==MeshTypePlane){
        return mesh.plane.normal;
    }
    return null;
}
#ifndef GL_ES
static inline f randomFloat(vec2 seed){
    return(float)rand()/(float)(RAND_MAX);
}
#else
float randomFloat(in vec2 _st){
    return fract(sin(dot(_st.xy*random,vec2(12.9898,78.233)))*43758.534534453123);
}
#endif
static Ray getChildRay(Object object,World world,vec3 point,Ray ray,vec2 seed){
    Material material=object.material;
    if(material.emission>0.){
        return Ray(vec3(0,0,0),vec3(0,0,0));
    }else if(material.reflectivity>0.){
        vec3 normal=normalVectorOfMeshAtPoint(object.mesh,point);
        vec3 direction=reflectIncidentNormal(ray.direction,normal);
        Ray newRay=Ray(point,direction);
        return newRay;
    }else if(true){
        if(true){
            vec3 normal=normalVectorOfMeshAtPoint(object.mesh,point);
            vec3 nl=dot(normal,ray.direction)<0.?normal:-normal;
            f r1=randomFloat(seed+vec2(.3*point.x-fract(point.z+point.y)*random,.2*point.y))*2.*M_PI;
            f r2=randomFloat(seed+vec2(2./point.z+point.x*point.y,.1+point.z));
            f r2s=sqrt(r2);
            vec3 w=nl;
            vec3 u=normalize(cross((abs(w.x)>.1?vec3(0,1,0):vec3(1,0,0)),w));
            vec3 v=cross(w,u);
            vec3 n=u*cos(r1)*r2s;
            vec3 g=v*sin(r1)*r2s;
            vec3 h=w*sqrt(1.-r2);
            vec3 d=normalize(n+g+h);
            
            Ray ray=Ray(point,d);
            return ray;
        }else{
            vec3 normal=normalVectorOfMeshAtPoint(object.mesh,point);
            f roughness=.8;
            vec3 reflected=reflectIncidentNormal(ray.direction,normal);
            reflected=normalize(vec3(
                    reflected.x+(randomFloat(seed)-.5)*roughness,
                    reflected.y+(randomFloat(seed*3.)-.5)*roughness,
                    reflected.z+(randomFloat(seed*4.)-.5)*roughness
                ));
                Ray ray=Ray(point,reflected);
                return ray;
            }
        }else{
            f ior=1.1;
            vec3 normal=normalVectorOfMeshAtPoint(object.mesh,point);
            f cosi=clamp(-1.,1.,dot(ray.direction,normal));
            f etai=1.;
            f etat=ior;
            vec3 n=normal;
            if(cosi<0.){
                cosi=-cosi;
            }else{
                f temp=etai;
                etai=etat;
                etat=temp;
                n=-normal;
            }
            float eta=etai/etat;
            float k=1.-eta*eta*(1.-cosi*cosi);
            vec3 dir=k<0.?vec3(0,0,0):ray.direction*eta+n*(cosi*eta-sqrt(k));
            return Ray(point,dir);
        }
    }
    static inline bool isZeroVector(vec3 vec){
        return vec.x==0.&&vec.y==0.&&vec.z==0.;
    }
    #ifdef GL_ES
    #define MAX_DEPTH 5
    #else
    #define MAX_DEPTH maxDepth
    #endif
    static inline Color trace(World world,Ray startRay,int maxDepth,vec2 seed,f time){
        Ray ray=startRay;
        Color c=white;
        for(int i=0;i<MAX_DEPTH;i++){
            f closestT=INFINITY;
            int closestObjectIndex=-1;
            for(int j=0;j<numObjects;j++){
                #ifndef GL_ES
                Object o=world.objects[j];
                #else
                Object o=getObject(j,time);
                #endif
                f result=intersect(o.mesh,ray);
                if(result<closestT&&result>.001&&(i>0||o.material.emission<1.)){
                    closestT=result;
                    closestObjectIndex=j;
                }
            }
            
            if(closestObjectIndex!=-1){
                vec3 point=ray.origin+ray.direction*closestT;
                #ifndef GL_ES
                Object o=world.objects[closestObjectIndex];
                #else
                Object o=getObject(closestObjectIndex,time);
                #endif
                ray=getChildRay(o,world,point,ray,seed+vec2(i,i*2));
                Material m=o.material;
                c=multiplyColor(c,m.color);
                if(isZeroVector(ray.direction)){
                    return c;
                }
            }else{
                return sky;
            }
        }
        return sky;
    }
    #ifdef GL_ES
    #define SAMPLES 100
    #else
    #define SAMPLES samples
    #endif
    static inline Color renderPixel(float x,float y,World world,Color prev,int samplesAlreadyRendered,int samples,Camera camera,f pixelWidth,f pixelHeight,f halfWidth,f halfHeight,vec2 seed,f time){
        f r=prev.r;
        f g=prev.g;
        f b=prev.b;
        for(int j=0;j<SAMPLES;j++){
            vec3 xComponent=camera.right*(((x+randomFloat(seed+vec2(x*random,f(j)*random)))*pixelWidth-halfWidth));
            vec3 yComponent=camera.up*(((y+randomFloat(seed+vec2(f(j)/random,x+y+random)))*pixelHeight-halfHeight));
            vec3 direction=normalize(camera.direction+xComponent+yComponent);
            
            Ray ray=Ray(camera.position,direction);
            
            f l=f(j+samplesAlreadyRendered);
            Color color=trace(world,ray,15,seed+vec2(9.-y*3.+x,l-x-99.),time);
            r+=(color.r-r)/(l+1.);
            g+=(color.g-g)/(l+1.);
            b+=(color.b-b)/(l+1.);
        }
        
        Color z=Color(r,g,b);
        return z;
    }
    #ifndef GL_ES
    static inline void render(World world,Image image,int start,int end,int increment,int samples,int samplesAlreadyRendered){
        Camera camera=world.camera;
        f aspectRation=((f)image.height)/((f)image.width);
        f halfWidth=tan(camera.angle);
        f halfHeight=aspectRation*halfWidth;
        f cameraWidth=halfWidth*2.;
        f cameraHeight=halfHeight*2.;
        f pixelWidth=cameraWidth/((f)image.width-1);
        f pixelHeight=cameraHeight/((f)image.height-1);
        int i=start;
        while(i<end){
            int x=i%image.width;
            int y=i/image.width;
            vec2 seed=vec2(x+samplesAlreadyRendered,y+i);
            Color prev=imageGetPixel(image,x,y);
            Color newColor=renderPixel((f)x,(f)y,world,prev,samplesAlreadyRendered,samples,camera,pixelWidth,pixelHeight,halfWidth,halfHeight,seed,0.);
            imageSetPixel(image,x,y,newColor);
            
            i+=increment;
        }
    }
    int main(int argc,const char*argv[]){
        int samplesPerRun=5;
        World world=createWorld();
        Image image=createImage(1000,1000);
        for(int i=0;i<400;i+=samplesPerRun){
            std::thread a(render,world,image,0,image.height*image.height,4,samplesPerRun,i);
            std::thread b(render,world,image,1,image.height*image.height,4,samplesPerRun,i);
            std::thread c(render,world,image,2,image.height*image.height,4,samplesPerRun,i);
            std::thread d(render,world,image,3,image.height*image.height,4,samplesPerRun,i);
            a.join();
            b.join();
            c.join();
            d.join();
            saveImage(image,argv[1]);
        }
        freeImage(image);
        freeWorld(world);
        return 0;
    }
    #else
    
    void main(void){
        vec2 position=gl_FragCoord.xy;
        f x=position.x;
        f y=position.y;
        vec2 q=position/resolution;
        vec2 uv=vec2(q.x,1.-q.y);
        
        World world=createWorld();
        Camera camera=world.camera;
        f aspectRation=(resolution.y)/(resolution.x);
        f halfWidth=tan(camera.angle);
        f halfHeight=aspectRation*halfWidth;
        f cameraWidth=halfWidth*2.;
        f cameraHeight=halfHeight*2.;
        f pixelWidth=cameraWidth/resolution.x;
        f pixelHeight=cameraHeight/resolution.y;
        
        Color prev=texture2D(texture,uv).xyz/5.;
        vec2 seed=vec2(x+random*time,y+time-random);
        Color newColor=renderPixel(x,y,world,prev,samples,-1,camera,pixelWidth,pixelHeight,halfWidth,halfHeight,seed,time);
        gl_FragColor=vec4(5.*newColor,1.);
    }
    #endif
    
    