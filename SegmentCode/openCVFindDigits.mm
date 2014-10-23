
//
//  openCVFindDigits.cpp
//  emptyExample
//
//  Created by Martijn Mellema on 14-10-14.
//
//

#include "openCVFindDigits.h"
#include "skewAngle.h"



using namespace cv;

string source_window = "Source image";

Mat mIntermediateMat;
Mat mRgba,matTest;

bool bDetecting = false;        // when set as true, the app will start to detect digitals
bool bIsUserView = false;    // when set as false, some intermediate value will be drawn to help debug

/**
 * we use a "locating box" to help locate digital area approximately
 */
#define I_BOX_WIDTH_RATIO .8

static double iBoxWidthRatio = 0.8;    // the ratio of the box width / the total width of camera preview
static double iBoxAspectRatio = 4.0; // the ratio of the box width / the box height
int iBoxTopLeftX;    // the x coordinate of the top left cv::Point of the box
int iBoxTopLeftY;    // the y coordinate of the top left cv::Point of the box
int iBoxWidth;        // the width of the box
int iBoxHeight;        // the height of the box

static int iDigitalDiffThre = 2;    // the threshold for the difference of project value between digital areas and non-digitals areas

// we use aspect ratio to check if an area is digital area
// that is, if the ratio is not in the given range, the area
// will be ignored
static double dDigitalRatioMin = 0.1;
static double dDigitalRatioMax = 0.8;

// the threshold for the variance of the digitals' widths
// Based on the priori knowledge that digitals are with equal widths,
// the variance of the widths must be less than the threshold
static double dDigitalWidthVarThre = 0.1;

// digital "1" is kind of special. We will recognize it
// according to its bounding rectangle's aspect ratio
static double dAspectRatioOne = 0.2;

/**
 * normally the digitals in LCD is a little slant. we should take
 * into account this when applying the vertical projection algorithm.
 * dDigitalSlope is the slope of the digital
 */
static double dDigitalSlope = 16.0;

vector<int> recog_results;

cv::Size sSize5;                // will be used for Gaussian blur


#define RAD_TO_DEG (180.0/PI)
#define PI       3.14159265358979323846


// take number image type number (from cv::Mat.type()), get OpenCV's enum string.
string getImgType(int imgTypeInt)
{
    int numImgTypes = 35; // 7 base types, with five channel options each (none or C1, ..., C4)
    
    int enum_ints[] =       {CV_8U,  CV_8UC1,  CV_8UC2,  CV_8UC3,  CV_8UC4,
        CV_8S,  CV_8SC1,  CV_8SC2,  CV_8SC3,  CV_8SC4,
        CV_16U, CV_16UC1, CV_16UC2, CV_16UC3, CV_16UC4,
        CV_16S, CV_16SC1, CV_16SC2, CV_16SC3, CV_16SC4,
        CV_32S, CV_32SC1, CV_32SC2, CV_32SC3, CV_32SC4,
        CV_32F, CV_32FC1, CV_32FC2, CV_32FC3, CV_32FC4,
        CV_64F, CV_64FC1, CV_64FC2, CV_64FC3, CV_64FC4};
    
    string enum_strings[] = {"CV_8U",  "CV_8UC1",  "CV_8UC2",  "CV_8UC3",  "CV_8UC4",
        "CV_8S",  "CV_8SC1",  "CV_8SC2",  "CV_8SC3",  "CV_8SC4",
        "CV_16U", "CV_16UC1", "CV_16UC2", "CV_16UC3", "CV_16UC4",
        "CV_16S", "CV_16SC1", "CV_16SC2", "CV_16SC3", "CV_16SC4",
        "CV_32S", "CV_32SC1", "CV_32SC2", "CV_32SC3", "CV_32SC4",
        "CV_32F", "CV_32FC1", "CV_32FC2", "CV_32FC3", "CV_32FC4",
        "CV_64F", "CV_64FC1", "CV_64FC2", "CV_64FC3", "CV_64FC4"};
    
    for(int i=0; i<numImgTypes; i++)
    {
        if(imgTypeInt == enum_ints[i]) return enum_strings[i];
    }
    return "unknown image type";
}


//--------------------------------------------------
float ofRadToDeg(float radians) {
    return radians * RAD_TO_DEG;
}




static float getSkewAngle(Mat gray)
{
    
    std::vector<cv::Vec4i> lines;
   

    
    cv::Size size = gray.size();
    
    int  max_value = 255;
    int  max_type = 4;
//    cv::GaussianBlur(gray, gray, sSize5, 2, 2);
//    
//    cvtColor(mIntermediateMat, mIntermediateMat, CV_8UC1);
//
   
    cv::HoughLinesP(gray, lines, 1, CV_PI/180, 100, size.width / 2.f, 20);
    unsigned nb_lines = lines.size();
    cv::Mat disp_lines(size, CV_8UC1, cv::Scalar(0, 0, 0));
    double angle = 0.;
    
    for (unsigned i = 0; i < nb_lines; ++i)
    {
        angle += atan2((double)lines[i][3] - lines[i][1],
                       (double)lines[i][2] - lines[i][0]);
    }
    angle /= nb_lines; // mean angle, in radians.
    
    float rad2Deg = -ofRadToDeg(angle);
    float degrees = (nb_lines != 0)? rad2Deg: 0;
    
    gray.release();
    return degrees;
}



void openCVFindDigits::findDigits(Mat mIntermediateMat)
{

    sSize5 = cv::Size(5, 5);
    

    /// Get the rotation matrix with the specifications above

    Scalar color_red( 255, 0, 0 );
    Scalar color_green( 0, 255, 0 );

  
    // do Gaussian blur to prevent getting lots false hits
    cv::GaussianBlur(mIntermediateMat, mIntermediateMat, sSize5, 2, 2);
    
    
    
   
    // use Canny edge detecting to get the contours in the image
    int iCannyLowerThre = 35;        // threshold for Canny detection
    int iCannyUpperThre = 75;        // threshold for Canny detection
    Canny(mIntermediateMat, mIntermediateMat, iCannyLowerThre, iCannyUpperThre);
    
    
  
    

    //mIntermediateMat =  skewAngle::rotateImage(mIntermediateMat.clone());
    
    cvtColor(mIntermediateMat, mRgba, COLOR_GRAY2BGRA, 4);
    
    
    float width = mIntermediateMat.size().width;
    float height = mIntermediateMat.size().height;
    
    // work out the size of locating box
    iBoxWidth = (int) (width * iBoxWidthRatio);
    iBoxHeight = (int) (iBoxWidth / iBoxAspectRatio);
    iBoxTopLeftX = (int) ((width - iBoxWidth) / 2.0);
    iBoxTopLeftY = (int) ((height - iBoxHeight) / 2.0);

    
    
    ShownImage = mRgba;
    
  
   
    // draw a slant line to show the slope
    cv::line(ShownImage, cv::Point(iBoxTopLeftX+iBoxWidth, iBoxTopLeftY),cv::Point(iBoxTopLeftX+iBoxWidth-iBoxHeight/dDigitalSlope, iBoxTopLeftY+iBoxHeight), color_green);
    // draw the locating box
    cv::rectangle( ShownImage, cv::Point(iBoxTopLeftX, iBoxTopLeftY), cv::Point(iBoxTopLeftX+iBoxWidth, iBoxTopLeftY+iBoxHeight), color_red, 2, 8, 0 );
    
  
    /**
     * scan vertically (with a little slant) to get the vertical projection of the image (in the box)
     * the projection is actually the number of white cv::Points in vertical direction
     */
    int digital_start = -1;
    int digital_end = -1;
    vector<int> digital_points;
    int vert_sum = 0;
    int pre_vert_sum = iBoxHeight;
    for (int i = iBoxTopLeftX; i < iBoxTopLeftX+iBoxWidth; i++) {
        vert_sum = 0;
        float endHeight  = iBoxTopLeftY+iBoxHeight;
        float beginHeight = iBoxTopLeftY;
        
        for (int j = beginHeight; j < endHeight; j++) {
            int next_x = (int) (i - (j - iBoxTopLeftY) / dDigitalSlope);
            int next_y = j;
            
            if (isWhitePoint(mIntermediateMat, next_x, next_y)) {
                vert_sum++;
            }
        }
        

        cv::line(ShownImage, cv::Point(i-iBoxHeight/dDigitalSlope, iBoxTopLeftY+iBoxHeight), cv::Point(i-iBoxHeight/dDigitalSlope, iBoxTopLeftY+iBoxHeight+vert_sum*10), color_red);

      
        
        if (digital_start < 0) {
            int diff = vert_sum - pre_vert_sum;
            if (diff >= iDigitalDiffThre) {
                digital_start = i - 1;
            }  else {
                pre_vert_sum = vert_sum;
            }
        } else {
            if (vert_sum <= pre_vert_sum) {
                digital_end = i;
                
                double ratio = (digital_end - digital_start)/((double) iBoxHeight);
                if (ratio > dDigitalRatioMin/2) {
                    digital_points.push_back(digital_start);        // record the left and right positions of the digital
                    digital_points.push_back(digital_end);
                }
                
                digital_start = -1;
                digital_end = -1;
            }
        }
    }
    
    /**
     * after finding the positions of the digitals, we will traverse
     * every digital from three different directions and then recognize
     * them based the traversal results.
     * see following example of digital "3". When we traverse it from
     * line a, b and c, the number of passed segments should be 3, 1 and 1 respectively.
     * Thus the recognition code of "3" is 311. That is, for an unknown digital,
     * if its code is "311", it should be digital "3".
     *
     *                 a
     *                /
     *           ####/#####
     *              /    #
     *    b -----------------
     *            /    #
     *       ####/#####
     *          /    #
     *   c -----------------
     *        /    #
     *    ###/#####
     *      /
     */
    
    // the vertical position of the line of the digitals
    int digitals_line_start = iBoxTopLeftY ;
    int line_height = iBoxHeight;
    
    //the thresholds for the three traversal directions
    double vert_mid_thre = 0.5;        // direction a
    double hori_upp_thre = 0.35;        // direction b
    double hori_low_thre = 0.7;         // direction c
    
    double vert_upp_seg_thre = 0.25;    // threshold for check if a segment is located upper when traversing from direction a
    double hori_left_seg_thre = 0.5;  // threshold for check if a segment is located left when traversing from direction b and c

    //    if (recog_results == null) {
    //        recog_results = new ArrayList<Integer>(); // array to record the recognition results
    //    }

    
    // draw bounding rectangles
    for (int i = 0; i < digital_points.size(); i += 2) {
        cv::rectangle(ShownImage, cv::Point(digital_points.at(i), iBoxTopLeftY), cv::Point(digital_points.at(i+1), iBoxTopLeftY+iBoxHeight), color_green, 2, 8, 0 );
    }
    
    matTest = ShownImage.clone();
    
    vector<int> digitals_widths; // widths of the digitals
    int widths_sum = 0;

    
    if (digital_points.size() > 0) {

        
        int recog_code = 0;     // recognition code
        for (int i = 0; i < digital_points.size(); i += 2) {
            recog_code = 0;
            
            int width = digital_points.at(i+1) - digital_points.at(i); // the width of a "digital area" (there might be a digital in it)
            
            /**
             * sometimes there might be some line above or below digitals
             * these lines should be removed to avoid wrong recognition
             * Thus we use horizontal project to specify the digital height
             * The basic idea is for a real digital area, its horizontal project
             * must be more than 0
             */
            int digital_hori_start = digitals_line_start;
            int hori_sum;
            int start_x = digital_points.at(i);
            int digital_hori_prj_cnt = 0;
            int tmp;
            for (tmp = digital_hori_start; tmp < digitals_line_start + line_height/2; tmp++) {
                hori_sum = 0;
                int next_x = (int) (start_x - (tmp - digitals_line_start) / dDigitalSlope);
                for (int k = 0; k < width; k++) {
                    if (isWhitePoint(mIntermediateMat, next_x+k, tmp)) {
                        hori_sum++;
                    }
                }
                
                if (hori_sum > 0) {
                    digital_hori_prj_cnt++;
                    if (digital_hori_prj_cnt == 5) {
                        digital_hori_start = tmp - 6;
                        break;
                    }
                } else {
                    digital_hori_prj_cnt = 0;
                }
            }
            
            if (tmp >= digitals_line_start + line_height/2) {
                continue; // not a digital
            }
            
            int digital_hori_end = digitals_line_start + line_height;
            digital_hori_prj_cnt = 0;
            for (tmp = digital_hori_end; tmp > digitals_line_start + line_height/2; tmp--) {
                hori_sum = 0;
                int next_x = (int) (start_x - (tmp - digitals_line_start) / dDigitalSlope);
                for (int k = 0; k < width; k++) {
                    if (isWhitePoint(mIntermediateMat, next_x+k, tmp)) {
                        hori_sum++;
                    }
                }
                
                if (hori_sum > 0) {
                    digital_hori_prj_cnt++;
                    if (digital_hori_prj_cnt == 5) {
                        digital_hori_end = tmp + 6;
                        break;
                    }
                } else {
                    digital_hori_prj_cnt = 0;
                }
            }
            
            if (tmp <= digitals_line_start + line_height/2) {
                continue; // not a digital
            }
            
            int digital_height = digital_hori_end-digital_hori_start+1;
            
            if (digital_height < iBoxHeight*0.5) {
                continue; // the digital should not be too short
            }
            
            // we use aspect ratio to validate the digital area
            double digital_ratio = width / ((double) digital_height);
            
            if (digital_ratio > dDigitalRatioMax
                || digital_ratio < dDigitalRatioMin) {
                continue;
            }
            
            if (digital_ratio < dAspectRatioOne) { // it should be digital "1" for the low aspect ratio
                if (i > 0 && digital_points.at(i) - 2 * width <= digital_points.at(i-1)) {
                    continue;    // if an "1" is too close to the previous digital, it should not be a wrong area
                }
                recog_results.push_back(1);
                continue;
            }
            
            int vert_line_x = (int) (start_x - (digital_hori_start-digitals_line_start) / dDigitalSlope + (width) * vert_mid_thre);
            int hori_upp_y = (int) (digital_hori_start + digital_height*hori_upp_thre);
            int hori_low_y = (int) (digital_hori_start + digital_height*hori_low_thre);
            
            // traverse from direction a
            vector<int> vertical_results = traverseRect(mIntermediateMat, vert_line_x, digital_hori_start, 0, digital_height);
            if (vertical_results.size() == 1) { // "4" or "7"
                if ((vertical_results.at(0) / ((double)digital_height)) < vert_upp_seg_thre ) {
                    recog_results.push_back(7);
                    digitals_widths.push_back(width);
                    widths_sum += width;
                } else {
                    recog_results.push_back(4);
                    digitals_widths.push_back(width);
                    widths_sum += width;
                }
                continue;
            }
            
            if (vertical_results.size() == 2) { // normally, only "0"'s vertical code is 2
                if ((vertical_results.at(1) - vertical_results.at(0))/((double)digital_height) < 0.6) {
                    recog_results.push_back(4);    // sometimes we got vertical code 2 for "4"
                    digitals_widths.push_back(width);
                    widths_sum += width;
                    continue;
                }
            }
            
            int hori_upp_x = (int) (start_x-(hori_upp_y - digitals_line_start)/dDigitalSlope);
            int hori_low_x = (int) (start_x-(hori_low_y - digitals_line_start)/dDigitalSlope);
            
            // traverse from direction b
            vector<int> horizontal_results_upp = traverseRect(mIntermediateMat, hori_upp_x, hori_upp_y, 1, width);
            
            // traverse from direction c
            vector<int> horizontal_results_low = traverseRect(mIntermediateMat, hori_low_x, hori_low_y, 1, width);
            
            // calculate the recognition code
            recog_code = vertical_results.size() * 100 + horizontal_results_upp.size() * 10 + horizontal_results_low.size();
            switch (recog_code) {
                case 322:
                    recog_results.push_back(8);
                    digitals_widths.push_back(width);
                    widths_sum += width;
                    break;
                case 321:
                    recog_results.push_back(9);
                    digitals_widths.push_back(width);
                    widths_sum += width;
                    break;
                case 312:
                    recog_results.push_back(6);
                    digitals_widths.push_back(width);
                    widths_sum += width;
                    break;
                case 311:
                    if ((horizontal_results_upp.at(0) / ((double)width)) < hori_left_seg_thre) {
                        recog_results.push_back(5);
                        digitals_widths.push_back(width);
                        widths_sum += width;
                    } else if ((horizontal_results_low.at(0) / ((double)width)) < hori_left_seg_thre) {
                        recog_results.push_back(2);
                        digitals_widths.push_back(width);
                        widths_sum += width;
                    } else {
                        recog_results.push_back(3);
                        digitals_widths.push_back(width);
                        widths_sum += width;
                    }
                    break;
                case 222:
                    recog_results.push_back(0);
                    digitals_widths.push_back(width);
                    widths_sum += width;
                    break;
                case 221:    // sometimes, we got the wrong vertical code 2 for "7". in this case, we have to check the full code
                    recog_results.push_back(7);
                    digitals_widths.push_back(width);
                    widths_sum += width;
                    break;
                default:
                    recog_results.push_back(-1);    // wrong recognition result :(
                    break;
            }
        }
        
        /**
         * the digitals should have equivalent widths.
         * We use this rule to check if we get the results
         */
    std::stringstream sRecogResults;
        if (isValidDigtals(digitals_widths, widths_sum)) {
            for (int i = 0; i < recog_results.size(); i++) {
                int digital = recog_results.at(i);
                if (digital >= 0) {
                    sRecogResults << ", "<<digital;
                } else {
                    sRecogResults << " NA , ";
                }
            }
            
        }
        cout<<sRecogResults.str()<<endl;
       
        }
        
        // print the results on the screen
        
       
      recog_results.clear();
  
    ShownImage.release();

    mIntermediateMat.release();
    
    mRgba.release();
}

string openCVFindDigits::getResults()
{
    return "";
}

Mat openCVFindDigits::getShownImage()
{
    return matTest;
}

Mat openCVFindDigits::getHoughTest()
{
    return matTest;
}



void openCVFindDigits::releaseMats () {
    
    mIntermediateMat.release();
    mRgba.release();
}

/**
 * Traverse the bounding rectangle from one direction to get segment code and position
 * @param mat the image matrix
 * @param start_x x coordinate of the starting cv::Point
 * @param start_y y coordinate of the starting cv::Point
 * @param direct traverse direction (0: vertical, 1: horizontal)
 * @param distance how far we will traverse
 * @return a list containing the results. When we detect a segment during traversing,
 * we will add the mid cv::Point coordinate (in the direction) of the segment to the list.
 * Thus, the size of the list would be the number of segments we found. We will
 * use this info and the coordinates (if needed) to get the recognition code of the digital.
 */
vector<int> openCVFindDigits::traverseRect(cv::Mat mat, int start_x, int start_y, int direct, int distance) {
    vector<int> results;
    vector<int> detected_points;
    
    // the threshold for the interval between segments
    double seg_inter_thre;
    if (direct == 1) {
        seg_inter_thre = distance * 0.33;
    } else {
        seg_inter_thre = distance * 0.25;
    }
    
    for (int i = 0; i < distance; i++) {
        int next_x = start_x;
        int next_y = start_y;
        if (direct == 0) {     // traverse vertically
            next_y += i;
            next_x = (int) (start_x - i / dDigitalSlope);
        } else {             // traverse horizontally
            next_x += i;
        }
        
        if (isWhitePoint(mat, next_x, next_y) || i == distance-1) {
            if (detected_points.size() > 0
                && (i - detected_points.at(detected_points.size()-1) > seg_inter_thre
                    || i == distance-1)) {
                    // should be another segment or we reach the end. So mark the current segment
                    int seg_mid = (int) ((detected_points.at(0) + detected_points.at(detected_points.size()-1)) / 2.0);
                    results.push_back(seg_mid);
                    
                    detected_points.clear();
                }
            
            if (i < distance-1)
                detected_points.push_back(i);
        }
    }
    
    return results;
}

static double white_thre = 100.0;

/**
 * check if a cv::Point in the image is white
 */
bool openCVFindDigits::isWhitePoint(Mat& mat, int x, int y) {
   double white_thre = 100.0;
    
    Vec3b tmp = mat.at<Vec3b>(y, x);
    int thres = tmp[0];

    if (thres < white_thre) {
        return false;
    } else {
        return true;
    }
}



/**
 * check if it is the "final" results are valid (the basic idea is based
 * on the priori knowledge that the widths of digitals should be equal)
 * @param widths the list of area widths
 * @param sum the sum of area widths
 * @return true if these widths are equivalent (we use variance as the indicator)
 */
bool openCVFindDigits::isValidDigtals(vector<int> widths, int sum) {
    if (widths.size() == 0) // no digital is detected
        return false;
    
    if (widths.size() == 1) // only one digital is detected
        return true;
    
    // print the results on the screen
    stringstream sRecogResultsTest;
    
    double avg = ((double) sum) / widths.size();
    double var_sum = 0.0;
    for (int i = 0; i < widths.size(); i++) {
        
        var_sum += pow(widths.at(i)-avg, 2);
        
        sRecogResultsTest << ", "<< widths.at(i);
    }
    
    double variance = var_sum / widths.size();
    
    sRecogResultsTest <<", "<< variance;
    
    cout<<"test results:      "<<sRecogResultsTest.str()<<endl;
    
    if (sqrt(variance)/avg < dDigitalWidthVarThre) {
        return true;
    } else {
        return false;
    }
}