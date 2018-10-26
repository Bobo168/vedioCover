//
//  ViewController.m
//  clearDimPic
//
//  Created by boboMa on 2018/10/25.
//  Copyright © 2018年 boboMa. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetImageGenerator.h>
#import <AVFoundation/AVTime.h>
@interface ViewController ()<UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *coverImg;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}
//竖屏视频封面处理
- (IBAction)portraitBtnClick:(id)sender {
   
    NSString *vedioPath = [[NSBundle mainBundle] pathForResource:@"portrait" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:vedioPath];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 1.获取视频第一帧图片
        UIImage *cover = [self getVideoPreViewImage:url];
        
        //2.按照比例截取封面图片
        
        //获取coverImg的宽高比例用于截取图片（竖屏这里截取的图片保持宽不变，以图片中心为基准，按照coverImg的比例裁剪的高，得到图片）
        CGFloat scale = self.coverImg.frame.size.width/self.coverImg.frame.size.height;
        //获取第一帧图片的大小（可以根据这个判断出来是横屏视频还是竖屏视频）
        CGSize size = cover.size;
        CGFloat clipH = size.width/scale;
        
        //获取按比例裁剪后的图片
        UIImage *clipImage = [self getImageByCuttingImage:cover Rect:CGRectMake(0, size.height/2-clipH/2, size.width,clipH)];
        //3.获取模糊图片
        UIImage *dimImg = [self coreBlurImage:clipImage withBlurNumber:30.0f];
        
        //获取模糊图大小
        UIImage *bottom = dimImg;
        CGImageRef imgRef1 = bottom.CGImage;
        CGFloat w1 = CGImageGetWidth(imgRef1);
        CGFloat h1 = CGImageGetHeight(imgRef1);
        
        //4. 获取放在封面中间的清晰图片
        UIImage *clearImg = [self thumbnailWithImageWithoutScale:cover size:CGSizeMake((size.height/h1)*w1, h1)];
        //获取清晰图片大小
        CGImageRef imgRef = clearImg.CGImage;
        CGFloat w = CGImageGetWidth(imgRef);
        CGFloat h = CGImageGetHeight(imgRef);
        
        //5.合成图片以模糊图片大小为画布创建上下文（以模糊图片为底图将清晰图放到模糊图中心）
        UIGraphicsBeginImageContext(CGSizeMake(w1, h1));
        [bottom drawInRect:CGRectMake(0, 0, w1, h1)];
        //把清晰图画到上下文中
        [clearImg drawInRect:CGRectMake(w1/2 - w/2, 0, w, h)];
        //6.获取合成图片
        UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();//从当前上下文中获得最终图片
        //关闭上下文
        UIGraphicsEndImageContext();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.coverImg.image = resultImg;
        });
        
    });
   
 
    
   
    
    
    
}



    
    
    

//横屏视频封面处理
- (IBAction)landscapeBtnClick:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"landscape" ofType:@"mp4"];
    
    NSURL *url = [NSURL fileURLWithPath:path];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 1.获取视频第一帧图片
        UIImage *cover = [self getVideoPreViewImage:url];
        
        //2.按照比例截取封面图片
        
        //获取coverImg的宽高比例用于截取图片（横屏这里截取的图片保持高不变，以图片中心为基准，按照coverImg的比例裁剪的宽，得到图片）
        CGFloat scale = self.coverImg.frame.size.width/self.coverImg.frame.size.height;
        CGSize size = cover.size;
        CGFloat clipW = size.height*scale;
        
        UIImage *resultImg = [self getImageByCuttingImage:cover Rect:CGRectMake(size.width/2 - clipW/2 , 0, clipW, size.height)];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.coverImg.image = resultImg;
        });
    });
   
    
    
    
}
//截取视频第一针
-(UIImage*)getVideoPreViewImage:(NSURL *)path
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:path options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return videoImage;
}
///裁剪正方形展示
-(UIImage *)getImageByCuttingImage:(UIImage *)image Rect:(CGRect)rect{
    
    //大图bigImage
    
    //定义myImageRect，截图的区域
    
    CGRect myImageRect = rect;
    
    UIImage* bigImage= image;
    
    CGImageRef imageRef = bigImage.CGImage;
    
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, myImageRect);
    
    CGSize size;
    
    size.width = rect.size.width;
    
    size.height = rect.size.height;
    
    UIGraphicsBeginImageContext(size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextDrawImage(context, myImageRect, subImageRef);
    
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    
    UIGraphicsEndImageContext();
    
    return smallImage;
    
}

//保持原来的长宽比，生成一个缩略图

-(UIImage *)thumbnailWithImageWithoutScale:(UIImage *)image size:(CGSize)asize

{
    
    UIImage *newimage;
    
    if (nil == image) {
        
        newimage = nil;
        
    }
    
    else{
        
        CGSize oldsize = image.size;
        
        CGRect rect;
        
        if (asize.width/asize.height > oldsize.width/oldsize.height) {
            
            rect.size.width = asize.height*oldsize.width/oldsize.height;
            
            rect.size.height = asize.height;
            
            rect.origin.x = (asize.width - rect.size.width)/2;
            
            rect.origin.y = 0;
            
        }
        
        else{
            
            rect.size.width = asize.width;
            
            rect.size.height = asize.width*oldsize.height/oldsize.width;
            
            rect.origin.x = 0;
            
            rect.origin.y = (asize.height - rect.size.height)/2;
            
        }
        
        UIGraphicsBeginImageContext(asize);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
        
        UIRectFill(CGRectMake(0, 0, asize.width, asize.height));//clear background
        
        [image drawInRect:rect];
        
        newimage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
    }
    
    return newimage;
    
}
//返回模糊图效果
- (UIImage *)coreBlurImage:(UIImage *)image withBlurNumber:(CGFloat)blur{
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:image.CGImage];
    //设置filter
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:@(blur) forKey:@"inputRadius"];
    //模糊图片
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    //CGImageRef outImage = [context createCGImage:result fromRect:[result extent]];
    CIImage *im = [CIImage imageWithCGImage:image.CGImage];
    CGImageRef outImage = [context createCGImage: result fromRect:[im extent]];
    UIImage *blurImage = [UIImage imageWithCGImage:outImage];
    CGImageRelease(outImage);
    return blurImage;
    
}

@end
