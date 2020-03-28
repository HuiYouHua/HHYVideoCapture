# HHYVideoCapture
视频采集

视频写入沙盒

视频硬编码：

1. 采集视频
2. 获取到视频帧
3. 对视频帧进行编码
4. 获取到视频帧信息
5. 将编码后的数据以NALU方式写入到文件



视频软编码：

​     FFMpeg+x.264编译

1. 软编码需要导入FFMpeg音视频处理库和X264视频编码函数库
2. 添加依赖库: libiconv.dylib/libz.dylib/libbz2.dylib/CoreMedia.framework/AVFoundation.framework
3. 设置header search path库头文件路径:$(SRCROOT)/HHYVideoCapture/软编码/FFmpeg-iOS/include
4. 设置bitcode为no
5. 注意:软编码需要注意视频采集的像素大小和编码视频大小要保持一致

​     而硬编码则没有关系

