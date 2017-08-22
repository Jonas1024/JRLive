//
//  GPUImageBeautifyFilter.m
//  JRLive
//
//  Created by fanjianrong on 2017/8/22.
//  Copyright © 2017年 樊健荣. All rights reserved.
//

#import "GPUImageBeautifyFilter.h"

@interface GPUImageCombinationFilter : GPUImageThreeInputFilter
{
    GLint smoothDegreeUniform;
}

@property (assign, nonatomic) CGFloat intensity;

@end

NSString *const kGPUImageBeautifyFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 varying highp vec2 textureCoordinate3;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D inputImageTexture3;
 uniform mediump float smoothDegree;
 
 void main ()
 {
     highp vec4 bilateral = texture2D(textureCoordinate, inputImageTexture);
     highp vec4 canny = texture2D(textureCoordinate2, inputImageTexture2);
     highp vec4 origin = texture2D(textureCoordinate3, inputImageTexture3);
     highp vec4 smooth;
     lowp float r = origin.r;
     lowp float g = origin.g;
     lowp float b = origin.b;
     if (canny.r < 0.2 && r > 0.3725 && g > 0.1568 && b > 0.0784 && r > b && (max(max(r, g), b) - min(min(r, g), b)) > 0.0588 && abs(r-g) > 0.0588) {
         smooth = (1.0 - smoothDegree) * (origin - bilateral) + bilateral;
     }
     else {
         smooth = origin;
     }
     smooth.r = log(1.0 + 0.2 * smooth.r)/log(1.2);
     smooth.g = log(1.0 + 0.2 * smooth.g)/log(1.2);
     smooth.b = log(1.0 + 0.2 * smooth.b)/log(1.2);
     gl_FragColor = smooth;
 }
);

@implementation GPUImageCombinationFilter

- (instancetype)init
{
    self = [super initWithFragmentShaderFromString:kGPUImageBeautifyFragmentShaderString];
    if (self) {
        smoothDegreeUniform = [filterProgram uniformIndex:@"smoothDegree"];
    }
    self.intensity = 0.5;
    return self;
}

- (void)setIntensity:(CGFloat)intensity
{
    _intensity = intensity;
    [self setFloat:intensity forUniform:smoothDegreeUniform program:filterProgram];
}

@end

@implementation GPUImageBeautifyFilter

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // first pass: face smooth filter
    //双边滤波磨皮
    bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    
    //distanceNormalizationFactor 越小磨皮效果越好，默认8.0
    bilateralFilter.distanceNormalizationFactor = 4.0;
    [self addFilter:bilateralFilter];
    
    // second pass: edge detection
    //边界
    cannyEdgeDetectionFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
    [self addFilter:cannyEdgeDetectionFilter];
    
    //third pass: combination bilateral, edge detection and origin
    combinationFilter = [[GPUImageCombinationFilter alloc] init];
    [self addFilter:combinationFilter];
    
    //adjust hsb
    hsbFilter = [[GPUImageHSBFilter alloc] init];
    [hsbFilter adjustBrightness:1.1];
    [hsbFilter adjustSaturation:1.1];
    
    [bilateralFilter addTarget:combinationFilter];
    [cannyEdgeDetectionFilter addTarget:combinationFilter];
    
    [combinationFilter addTarget:hsbFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:bilateralFilter, cannyEdgeDetectionFilter, combinationFilter, nil];
    self.terminalFilter = hsbFilter;
    
    return self;
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex
{
    
    for (GPUImageOutput<GPUImageInput> *currentfilter in self.initialFilters) {
        if (currentfilter != self.inputFilterToIgnoreForUpdates) {
            if (currentfilter == combinationFilter) {
                
                textureIndex = 2;
            }
            [currentfilter newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex
{
    for (GPUImageOutput<GPUImageInput> *currentfilter in self.initialFilters) {
        if (currentfilter != self.inputFilterToIgnoreForUpdates) {
            if (currentfilter == combinationFilter) {
                textureIndex = 2;
            }
            [currentfilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
        }
    }
}





@end
