//
//  skewAngle.h
//  7-segment
//
//  Created by Martijn Mellema on 22-10-14.
//  Copyright (c) 2014 Martijn Mellema. All rights reserved.
//

#ifndef ____segment__skewAngle__
#define ____segment__skewAngle__

#include <stdio.h>
#include <opencv2/opencv.hpp>
using namespace cv;
using namespace std;

class skewAngle
{
private:
    static  void hough_transform(Mat& im,Mat& orig,double* skew);
    static Mat preprocess1(Mat& im);
    static Mat preprocess2(Mat& im);
    static Mat rot(Mat& im,double thetaRad);
    
public:
    static Mat rotateImage(Mat);
    
};

#endif /* defined(____segment__skewAngle__) */
