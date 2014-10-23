//
//  openCVFindDigits.h
//  emptyExample
//
//  Created by Martijn Mellema on 14-10-14.
//
//

#ifndef __emptyExample__openCVFindDigits__
#define __emptyExample__openCVFindDigits__

#include <stdio.h>
#include <vector>

#import <UIKit/UIKit.h>

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

using namespace cv;
using namespace std;

class openCVFindDigits
{
public:
    void findDigits(Mat);
    string getResults();
    Mat getShownImage();
    Mat getHoughTest();
private:
    static bool isValidDigtals(vector<int> widths, int sum);
    static void releaseMats() ;
    static bool isWhitePoint(cv::Mat& mat, int x, int y);
    
    static vector<int> traverseRect(cv::Mat mat, int start_x, int start_y, int direct, int distance);
    
    cv::Mat ShownImage;
    cv::Mat houghTest;
   
    

};

#endif /* defined(__emptyExample__openCVFindDigits__) */
