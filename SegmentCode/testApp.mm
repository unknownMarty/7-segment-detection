#include "testApp.h"


#include "ofxCv.h"

using namespace ofxCv;
using namespace cv;

ofImage img,scaled;

bool sortLinesFunction (pair<ofPoint, ofPoint> i,pair<ofPoint, ofPoint> j ) {
    return (i.first.distance(i.second) < j.first.distance(j.second)); }

bool sortLinesCountedFunction (vector< lineType>  i,vector< lineType> j ) {
    return (i.size() > j.size()); }

//--------------------------------------------------------------
void testApp::setup(){
    
    cout<<"opencv version : "<<CV_MAJOR_VERSION<<endl;
    cout<<"opencv version : "<<CV_MINOR_VERSION<<endl;
    

    // #1 Play videos with an alpha channel. ---------------------------
    // ofQTKitPlayer videos encoded with Alpha channels (e.g. Animation Codec etc).
    // The pixel format MUST be enabled prior to loading!
    // If an alpha channels is not used, setting a non-alpha pixel format
    // (e.g. OF_PIXELS_RGB) will increase performance.
    digitMovie.setPixelFormat(OF_PIXELS_RGBA);
    
  
   
    digitMovie.loadMovie("IMG_0380.MOV");
    digitMovie.play();
    

   
}



//--------------------------------------------------------------
void testApp::update(){
    digitMovie.update();
}

//--------------------------------------------------------------
void testApp::draw(){
   
    ofSetHexColor(0x000000);
    if (digitMovie.isLoaded()) {
       // digitMovie.draw(20, 20);
      
            
    
            ofImage digitImg(digitMovie.getPixelsRef());
            float degrees = getSkewAngle(digitImg,digitImg.getPixelsRef(),digitImg.getPixels());
            
                        // let's move through the "RGB(A)" char array
            // using the red pixel to control the size of a circle.
            ofPushMatrix();
            
            
            ofPopMatrix();
            
       
            ofImage rotatedImage = rotatePixels(digitImg, degrees);
            
            if(rotatedImage.getPixels() != NULL)
            {
                openCVFindDigits findDigits(rotatedImage);

                 drawCircles(findDigits.getShownImage().getPixelsRef(), findDigits.getShownImage().getPixels());
            
                cout<<"results : "<<findDigits.getResults()<<endl;
            }
            

            if(rotatedImage.getPixels() != NULL)
            {
                ofPushMatrix();
                ofTranslate(400, 0);
                drawCircles(rotatedImage.getPixelsRef(), rotatedImage.getPixels());
            }
                
//                Mat mat = toCv(rotatedImage.getPixelsRef());
//                
//                
//                std::vector<cv::Rect> rects =  detectLetters(mat);
//                //Display
//                ofSetColor(ofColor::red);
//                ofNoFill();
//                for(int i=0; i< rects.size(); i++)
//                {
//                    ofRectangle rect = toOf(rects[i]);
//                   // ofRect(rect);
//                }
                
                //ofImage templ("digits/0.PNG");
                //cv::Mat t = toCv(templ);
                
//                vector<cv::Point> points = MatchingMethod(0,mat, t);
//                ofSetColor(ofColor::red);
//                for(int i=0; i< points.size(); i++)
//                {
//                    ofPoint pt = toOf(points[i]);
//                    ofCircle(pt, 50);
//                }
                
//                
//                vector<ofPoint> points = cornerHarris_demo(mat,50);
//                ofSetColor(ofColor::red);
//                for(int i=0; i< points.size(); i++)
//                {
//                    ofPoint pt = points[i];
//                    ofCircle(pt, 1);
//                }
                
/*
                vector<pair<ofPoint,ofPoint> > lines = getHoughLines(mat);
                ofSetColor(ofColor::blue);
//                for(int i=0; i< lines.size(); i++)
//                {
//                    ofPoint pt1 = lines[i].first;
//                    ofPoint pt2 = lines[i].second;
//                    ofCircle(pt1, 1);
//                    ofCircle(pt2, 1);
//                }
 */
                
       /*         vector<pair<ofPoint,ofPoint> > sortLines = lines;
                std::sort (sortLines.begin(), sortLines.end(), sortLinesFunction);
                
                
                vector<vector< lineType> > linesCounted;
                linesCounted.push_back(vector< lineType> ());
                
                for(int i=0; i< sortLines.size(); i++)
                {
                    
                    lineType type = make_lineType(sortLines[i].first,sortLines[i].second);
                    
                    if(i+1 < sortLines.size())
                    {
                        lineType typeNext = make_lineType(sortLines[i+1].first,sortLines[i+1].second);
                        
                        if(round(type.distance) == round(typeNext.distance))
                            linesCounted.back().push_back(typeNext);
                        else
                            linesCounted.push_back(vector< lineType> ());
                    }
                }
                std::sort (linesCounted.begin(), linesCounted.end(), sortLinesCountedFunction);
                
                for(int x=0; x< linesCounted.size(); x++)
                {
                    if(linesCounted[x].size() > 20)
                    {
                        
                    for(int i=0; i< linesCounted[x].size(); i++)
                    {
                        ofPoint pt1 = linesCounted[x][i].beg;
                        ofPoint pt2 = linesCounted[x][i].end;
                        ofLine(pt1,pt2);
                    }
                    }
                }
                ofFill();

                
                ofPopMatrix();
                mat.release();
            }
            ofPopMatrix();
        */
        }
    

}

void testApp::drawCircles(ofPixelsRef pixelsRef,unsigned char * pixels)
{
  
    for(int i = 4; i < digitMovie.getWidth(); i += 2){
        for(int j = 4; j < digitMovie.getHeight(); j += 2){
            int pixelArrayIndex = pixelsRef.getPixelIndex(i,j);
            unsigned char r = pixels[(j * 320 + i) * pixelsRef.getNumChannels()];
            float val = 1 - ((float)r / 255.0f);
            ofSetColor(pixelsRef.getColor(i, j));
            ofCircle( i, 20 + j, 5 * val);
        }
    }

}

float testApp::getSkewAngle(ofImage digitImg, ofPixelsRef pixelsRef,unsigned char * pixels)
{
    Mat mat = toCv(pixelsRef);
    std::vector<cv::Vec4i> lines;
    Mat gray,gray_Thres;
    
    copyGray(mat,gray);
   
    
    cv::Size size = mat.size();
    
    int const max_value = 255;
    int const max_type = 4;

    threshold( gray, gray_Thres, 225, max_type,0 );
    cv::HoughLinesP(gray_Thres, lines, 1, CV_PI/180, 100, size.width / 2.f, 20);
    unsigned nb_lines = lines.size();
    cv::Mat disp_lines(size, CV_8UC1, cv::Scalar(0, 0, 0));
    double angle = 0.;
    
    
    for (unsigned i = 0; i < nb_lines; ++i)
    {
        angle += atan2((double)lines[i][3] - lines[i][1],
                       (double)lines[i][2] - lines[i][0]);
    }
    angle /= nb_lines; // mean angle, in radians.
    
    float degrees = -ofRadToDeg(angle);
    
   // drawSkewAngle(digitImg, degrees, lines);
    
    mat.release();
    gray.release();
    gray_Thres.release();
    return degrees;
}


void testApp::drawSkewAngle(ofImage digitImg,float degrees,std::vector<cv::Vec4i> lines)
{

    unsigned char * pixels = digitImg.getPixels();
    ofPixelsRef pixelsRef = digitImg.getPixelsRef();
    ofPushMatrix();
    ofSetColor(ofColor::blue);
    ofCircle(0, 0, 10);
    ofTranslate(digitImg.getWidth()/2, digitImg.getHeight()/2);
    ofPushMatrix();
    ofSetColor(ofColor::blue);
    ofCircle(0, 0, 10);
    ofRotateZ(degrees );
    ofTranslate(-digitImg.getWidth()/2, -digitImg.getHeight()/2);
    ofSetHexColor(0x000000);
    
    ofSetColor(ofColor::red);
    for (unsigned i = 0; i < lines.size(); ++i)
    {
        ofLine(ofPoint(lines[i][0], lines[i][1]),ofPoint(lines[i][2], lines[i][3]));
    }
    ofSetColor(ofColor::blue);
    ofCircle(0, 0, 10);
    drawCircles(pixelsRef,pixels);
    ofPopMatrix();
    ofPopMatrix();

}


std::vector<cv::Rect> testApp::detectLetters(cv::Mat img)
{
    std::vector<cv::Rect> boundRect;
    cv::Mat img_gray, img_sobel, img_threshold, element;

    cvtColor(img, img_gray, CV_BGR2GRAY);
    
    cv::Sobel(img_gray, img_sobel, CV_8U, 1, 0, 3, 1, 0, cv::BORDER_DEFAULT);
    cv::threshold(img_sobel, img_threshold, 0, 255, CV_THRESH_OTSU+CV_THRESH_BINARY);
    element = getStructuringElement(cv::MORPH_RECT, cv::Size(17, 3) );
    cv::morphologyEx(img_threshold, img_threshold, CV_MOP_CLOSE, element); //Does the trick
    std::vector< std::vector< cv::Point> > contours;
    cv::findContours(img_threshold, contours, 0, 1);
    std::vector<std::vector<cv::Point> > contours_poly( contours.size() );
    for( int i = 0; i < contours.size(); i++ )
        if (contours[i].size()>100)
        {
            cv::approxPolyDP( cv::Mat(contours[i]), contours_poly[i], 3, true );
            cv::Rect appRect( boundingRect( cv::Mat(contours_poly[i]) ));
            if (appRect.width>appRect.height)
                boundRect.push_back(appRect);
        }
    return boundRect;
}

/**
 * @function MatchingMethod
 * @brief Trackbar callback
 */
vector<cv::Point> testApp::MatchingMethod(int match_method, cv::Mat img, cv::Mat templ  )
{
    match_method = CV_TM_CCOEFF;
    /// Source image to display
    vector<cv::Point> points;
    Mat img_display,result;
    img.copyTo( img_display );

    /// Create the result matrix
    int result_cols =  img.cols - templ.cols + 1;
    int result_rows = img.rows - templ.rows + 1;
    
    result.create( result_cols, result_rows, CV_32FC1 );
    
    /// Do the Matching and Normalize
    
    matchTemplate( img, templ, result, match_method );
    normalize( result, result, 0, 1, NORM_MINMAX, -1, Mat() );
    
    /// Localizing the best match with minMaxLoc
    double minVal; double maxVal; cv::Point minLoc; cv::Point maxLoc;
    cv::Point matchLoc;
    
    minMaxLoc( result, &minVal, &maxVal, &minLoc, &maxLoc, Mat() );
    
    /// For SQDIFF and SQDIFF_NORMED, the best matches are lower values. For all the other methods, the higher the better
    if( match_method  == CV_TM_SQDIFF || match_method == CV_TM_SQDIFF_NORMED )
    { matchLoc = minLoc; }
    else
    { matchLoc = maxLoc; }
    
    /// Show me what you got
    cv::Point  pt = cv::Point( matchLoc.x + templ.cols , matchLoc.y + templ.rows );
    points.push_back(pt);
    

    return points;
}

/** @function cornerHarris_demo */
vector<ofPoint> testApp::cornerHarris_demo(Mat src,int thresh = 200)
{
    vector<ofPoint> points;
    Mat dst, dst_norm, dst_norm_scaled;
    dst = Mat::zeros( src.size(), CV_32FC1 );
    
    /// Detector parameters
    int blockSize = 2;
    int apertureSize = 3;
    double k = 0.04;
    
    Mat src_gray;
    copyGray(src, src_gray);
    Canny(src_gray, src_gray, 100, 200);
    /// Detecting corners
    cornerHarris( src_gray, dst, blockSize, apertureSize, k, BORDER_DEFAULT );
    
    /// Normalizing
    normalize( dst, dst_norm, 0, 255, NORM_MINMAX, CV_32FC1, Mat() );
    convertScaleAbs( dst_norm, dst_norm_scaled );
    
    /// Drawing a circle around corners
    for( int j = 0; j < dst_norm.rows ; j++ )
    { for( int i = 0; i < dst_norm.cols; i++ )
    {
        if( (int) dst_norm.at<float>(j,i) > thresh )
        {
            points.push_back(toOf(cv::Point( i, j )));
        }
    }
    }
    return points;
}

vector<pair<ofPoint,ofPoint> > testApp::getHoughLines(Mat src)
{
    vector<pair<ofPoint,ofPoint> > retLines;
    Mat dst, cdst,src_gray;
    
    copyGray(src, src_gray);
    cv::blur(src_gray,src_gray, cv::Size(3,3));
    
    Canny(src_gray, dst, 200, 50, 3);
    cvtColor(dst, cdst, CV_GRAY2BGR);
    vector<Vec4i> lines;
    
    cv::Size size = dst.size();
    
     HoughLinesP(dst, lines, 1, CV_PI/180, 5,5, 5 );
    
    //HoughLinesP( InputArray image, OutputArray lines,
//    double rho, double theta, int threshold,
  //  double minLineLength=0, double maxLineGap=0 );
    
//    cv::HoughLinesP(dst, lines, 1, CV_PI/180, 5, size.width / 5.f);
    for( size_t i = 0; i < lines.size(); i++ )
    {
        Vec4i l = lines[i];
        pair<ofPoint, ofPoint> line;
        line.first =  toOf(cv::Point(l[0], l[1]));
        line.second =  toOf(cv::Point(l[2], l[3]));
        retLines.push_back(line);
    }
    
    return retLines;
}

ofImage testApp::rotatePixels(ofImage source,float angle)
{
    ofImage result;
    result.clear();
    result.clone(source);
    int w = source.width;
    int h = source.height;
    int cx = w/2; //center
    int cy = h/2;
    int bpp = 4;
    
    //make result background black by setting memory to 0
    if(source.getPixels() != NULL)
    {
        
    memset(result.getPixels(), 0, bpp*w*h);
    
    for (int y=0; y<h; y++) {
        for (int x=0; x<w; x++) {
            
            // xx range between -cx..0..cx instead of 0..w
            // so we're changing the pivot point from topleft to center
            int xx = x - cx;
            int yy = y - cy;
            
            //distance from pixel to center of image
            float r = sqrt(xx*xx+yy*yy);
            
            //current angle of pixel + rotation angle
            float phi = atan2(yy,xx) + HALF_PI + ofDegToRad(angle);
            
            //calculate new pixel position
            xx = r*sin(phi) + cx;
            yy = r*cos(phi) + cy;
            
            // if out of bounds leave background black
            if (xx<0 || yy<0 || xx>w || yy>h) continue;
            
            //calculate position of pixel in array
            unsigned char *to = result.getPixels() + bpp*y*w + bpp*x;
            unsigned char *from = source.getPixels() + bpp*yy*w + bpp*xx;
            
            memcpy(to, from, bpp);
            
        }
    }
    result.mirror(true, false);
    result.update();
    }
    
    return result;
}

//--------------------------------------------------------------
void testApp::mousePressed(int x, int y, int button){

}

