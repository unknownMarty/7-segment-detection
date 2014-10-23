#ifndef _TEST_APP
#define _TEST_APP


#include "ofMain.h"
#include "ofxCv.h"

#include "openCVFindDigits.h"

typedef struct
{
    ofPoint beg;
    ofPoint end;
    float distance;
    
} lineType;

class testApp : public ofBaseApp{

	public:
		void setup();
		void update();
		void draw();
    string runOcr(float scale, int medianSize) ;

    static lineType make_lineType(ofPoint beg,ofPoint end )
    {
        lineType t;
        t.beg = beg;
        t.end = end;
        t.distance  = t.beg.distance(t.end);
        return t;
    }
    
		void mousePressed(int x, int y, int button);
    void drawCircles(ofPixelsRef pixelsRef,unsigned char * pixels);
    float getSkewAngle(ofImage digitImg,ofPixelsRef _pixelsRef,unsigned char * pixels);
    void drawSkewAngle(ofImage digitImg,float degrees,std::vector<cv::Vec4i> lines);
    ofVideoPlayer 		digitMovie;
    std::vector<cv::Rect> detectLetters(cv::Mat img);
    ofImage rotatePixels(ofImage source,float angle);
    vector<cv::Point> MatchingMethod(int match_method, cv::Mat img, cv::Mat templ  );
    
    vector<ofPoint> cornerHarris_demo(cv::Mat src,int thresh);
    vector<pair<ofPoint,ofPoint> > getHoughLines(cv::Mat mat);
};

#endif
