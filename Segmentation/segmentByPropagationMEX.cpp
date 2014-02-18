/***************************************************************
 * Segmentation by Propagation
 * using Relative Intensity Changes
 *
 * C. Kirst, The Rockefeller University 2014
 *
 * Segmentation is done by propagation from the seeds
 * stopping if a distance measure is to large
 * For images with objects of strong variying intensity 
 * dividing the distance change by the objects center intensity 
 * increases the performance
 * Distance is calculated as geodesic distance
 *
 * Code based on the propagation algorithm in CellProfiler
 *
 ***************************************************************/

#include <math.h>
#include "mex.h"
#include <queue>
#include <vector>
#include <map>
#include <iostream>
using namespace std;

/* Input Arguments */
#define IM_IN              prhs[0]
#define LABELS_IN          prhs[1]
#define MASK_IN            prhs[2]
#define LAMBDA_IN          prhs[3]
#define RADIUS_IN          prhs[4]
#define INTENSITY_REF_IN   prhs[5]

/* Output Arguments */
#define LABELS_OUT        plhs[0]
#define DISTANCES_OUT     plhs[1]
#define DIFF_COUNT_OUT    plhs[2]
#define POP_COUNT_OUT     plhs[3]

#define IJ(i,j) ((j)*m+(i))

static double *difference_count = 0;
static double *pop_count = 0;

class Pixel { 
public:
  double distance;
  unsigned int i, j;
  double label;
  Pixel (double ds, unsigned int ini, unsigned int inj, double l) : 
    distance(ds), i(ini), j(inj), label(l) {}
};

struct Pixel_compare { 
 bool operator() (const Pixel& a, const Pixel& b) const 
 { return a.distance > b.distance; } // smallest element is processed next
};

typedef priority_queue<Pixel, vector<Pixel>, Pixel_compare> PixelQueue;

static double
clamped_fetch(double *image, 
              int i, int j,
              int m, int n)
{
  if (i < 0) i = 0;
  if (i >= m) i = m-1;
  if (j < 0) j = 0;
  if (j >= n) j = n-1;

  return (image[IJ(i,j)]);
}


/* average intensity around a point */
static double
average_intensity(double * image, 
                  int i,  int j,
                  unsigned int m, unsigned int n, int radius)
{
  int delta_i, delta_j;
  double intensity = 0.0;

  // Calculate average pixel intensities
  for (delta_j = -radius; delta_j <= radius; delta_j++) {
    for (delta_i = -radius; delta_i <= radius; delta_i++) {
      intensity += clamped_fetch(image, i + delta_i, j + delta_j, m, n);
    }
  }
  return (intensity/((radius+1.0)*(radius+1.0)));
}



/* difference between two pixels */
static double
Difference(double *image,
           int i1,  int j1,
           int i2,  int j2,
           unsigned int m, unsigned int n, 
           int radius, double ref_intensity,  double lambda)
{
  int delta_i, delta_j;
  double pixel_diff = 0.0;
  (*difference_count)++; 

  // Calculate average pixel difference
  for (delta_j = -radius; delta_j <= radius; delta_j++) {
    for (delta_i = -radius; delta_i <= radius; delta_i++) {
      //pixel_diff += fabs(clamped_fetch(image, i1 + delta_i, j1 + delta_j, m, n) - 
      //                   clamped_fetch(image, i2 + delta_i, j2 + delta_j, m, n));
       
        pixel_diff += fabs(clamped_fetch(image, i1 + delta_i, j1 + delta_j, m, n) - ref_intensity);   
    }
  }
  pixel_diff *= 1.0/((radius+1.0)*(radius+1.0)*ref_intensity);
 
  // distance (is 'semi geodesic') 
  double space_diff = sqrt(((double) i1 - i2)  * ((double) i1 - i2) +  ((double) j1 - j2)  * ((double) j1 - j2));  
  
  //here is space for taking into account gradient image / gradient crossings form the label center to the new pixel etc....
  
  return ((1 - lambda) * pixel_diff + space_diff * lambda /* * lambda*/);
}




static void
push_neighbors_on_queue(PixelQueue &pq, double dist,
                        double *image,
                        unsigned int i, unsigned int j,
                        unsigned int m, unsigned int n,
                        int radius, double ref_intensity,  double lambda, 
                        double label, double *labels_out, mxLogical* mask_in)
{
    
  /* 4-connected */
  if (i > 0) {
    if ( mask_in[IJ(i-1,j)] &&  0 == labels_out[IJ(i-1,j)] /* && image[IJ(i-1,j)] > threshold */) // if the neighbor was not labeled - threshold is taken care of by the mask
      pq.push(Pixel(dist + Difference(image, i, j, i-1, j, m, n, radius, ref_intensity, lambda), i-1, j, label));
  }                                                                   
  if (j > 0) {                                                        
    if ( mask_in[IJ(i,j-1)] &&  0 == labels_out[IJ(i,j-1)]/* && image[IJ(i,j-1)] > threshold */ )   
      pq.push(Pixel(dist + Difference(image, i, j, i, j-1, m, n, radius, ref_intensity, lambda), i, j-1, label));
  }                                                                   
  if (i < (m-1)) {
    if ( mask_in[IJ(i+1,j)] &&  0 == labels_out[IJ(i+1,j)] /* && image[IJ(i+1,j)] > threshold */) 
      pq.push(Pixel(dist + Difference(image, i, j, i+1, j, m, n, radius, ref_intensity, lambda), i+1, j, label));
  }                                                                   
  if (j < (n-1)) {              
    if ( mask_in[IJ(i,j+1)] &&  0 == labels_out[IJ(i,j+1)] /* && image[IJ(i,j+1)] > threshold */)   
      pq.push(Pixel(dist + Difference(image, i, j, i, j+1, m, n, radius, ref_intensity, lambda), i, j+1, label));
  } 

  /* 8-connected */
  if ((i > 0) && (j > 0)) {
    if ( mask_in[IJ(i-1,j-1)] && 0 == labels_out[IJ(i-1,j-1)] /*  && image[IJ(i-1,j-1)] > threshold */)   
      pq.push(Pixel(dist + Difference(image, i, j, i-1, j-1, m, n, radius, ref_intensity, lambda), i-1, j-1, label));
  }                                                                       
  if ((i < (m-1)) && (j > 0)) {                                           
    if ( mask_in[IJ(i+1,j-1)] && 0 == labels_out[IJ(i+1,j-1)] /* && image[IJ(i+1,j-1)] > threshold */)    
      pq.push(Pixel(dist + Difference(image, i, j, i+1, j-1, m, n, radius, ref_intensity, lambda), i+1, j-1, label));
  }                                                                       
  if ((i > 0) && (j < (n-1))) {                                           
    if ( mask_in[IJ(i-1,j+1)] && 0 == labels_out[IJ(i-1,j+1)] /* && image[IJ(i-1,j+1)] > threshold */)   
      pq.push(Pixel(dist + Difference(image, i, j, i-1, j+1, m, n, radius, ref_intensity, lambda), i-1, j+1, label));
  }                                                                       
  if ((i < (m-1)) && (j < (n-1))) {
    if ( mask_in[IJ(i+1,j+1)] && 0 == labels_out[IJ(i+1,j+1)] /* && image[IJ(i+1,j+1)] > threshold */)   
      pq.push(Pixel(dist + Difference(image, i, j, i+1, j+1, m, n, radius, ref_intensity, lambda), i+1, j+1, label));
  }
  
}

static void propagate(double *labels_in, double *im_in, mxLogical *mask_in, 
                      double *labels_out, 
                      double *dists,
                      unsigned int m, unsigned int n,
                      int radius,
                      double *center_intensities, unsigned int nlabel,
                      double lambda)
{

  unsigned int i, j;
  PixelQueue pixel_queue;
  //map<double, double> center_intensities;  / for auto center_intensities 
  
  
  /* initialize dist to Inf, read labels_in and wrtite out to labels_out */
  for (j = 0; j < n; j++) {
    for (i = 0; i < m; i++) {
      dists[IJ(i,j)] = mxGetInf();            
      labels_out[IJ(i,j)] = labels_in[IJ(i,j)];
    }
  }
  
  /* if the pixel is already labeled (i.e, labeled in labels_in) and within a mask, 
   * then set dist to 0 and push its neighbors for propagation */
  for (j = 0; j < n; j++) {
    for (i = 0; i < m; i++) {        
      double label = labels_in[IJ(i,j)];
      if ((label > 0) && (mask_in[IJ(i,j)])) {
         
        
        if ((int) label >= nlabel || ( (int) label < 0) || (fabs(label - (int) label) > 0) ) {
           //cout << label << " " << (int) label << " " << fabs(label - (int) label) << " "<< nlabel << endl;
           //cout << ((int) label >= nlabel) << " " << ((int) label < 0) << " " <<  (fabs(label - (int) label) > 0) << endl;

           mexErrMsgTxt("Inconsistent label of seeds, should be integer from 1 - nlabel, 0 for background %g.");
        };
          
        dists[IJ(i,j)] = 0.0;
        
        /* auto initialize intensities */
        /*
        double norm = 1.0;
        if (radius_center >= 0) {
            norm = average_intensity(im_in, i, j, m, n, radius_center);
        }
        center_intensities[label] = norm;
        */

        push_neighbors_on_queue(pixel_queue, 0.0, im_in, i, j, m, n, radius, center_intensities[(int) label], lambda, label, labels_out, mask_in);
        
      }
    }
  }

  while (! pixel_queue.empty()) {
    Pixel p = pixel_queue.top();
    pixel_queue.pop();
    (*pop_count)++;  
    //cout << "popped " << p.i << " " << p.j << endl;

    if ((dists[IJ(p.i, p.j)] > p.distance) /* && (mask_in[IJ(p.i,p.j)])*/) {
      dists[IJ(p.i, p.j)] = p.distance;
      labels_out[IJ(p.i, p.j)] = p.label;      
      push_neighbors_on_queue(pixel_queue, p.distance, im_in, p.i, p.j, m, n, 
                              radius, center_intensities[(int) p.label], lambda, p.label, labels_out, mask_in);
    }
  }
}

void mexFunction( int nlhs, mxArray *plhs[], 
                  int nrhs, const mxArray*prhs[] )
     
{ 
    double *labels_in, *im_in; 
    mxLogical *mask_in;
    double *labels_out, *dists;
    double *lambda;
    int radius /*, radius_center*/;    
    unsigned int m, n; 
    
    double *intensity_refs;
    unsigned int nlabel;
    
    /* Check for proper number of arguments */
    
    if (nrhs != 6) { 
        mexErrMsgTxt("6 input arguments required."); 
    } else if (nlhs !=1 && nlhs !=2 && nlhs !=4) {
        mexErrMsgTxt("The number of output arguments should be 1, 2, or 4."); 
    } 

    m = mxGetM(IM_IN); 
    n = mxGetN(IM_IN);

    if ((m != mxGetM(LABELS_IN)) ||
        (n != mxGetN(LABELS_IN))) {
      mexErrMsgTxt("First and second arguments must have same size.");
    }

    if ((m != mxGetM(MASK_IN)) ||
        (n != mxGetN(MASK_IN))) {
      mexErrMsgTxt("First and third arguments must have same size.");
    }

    if (! mxIsDouble(IM_IN)) {
      mexErrMsgTxt("First argument must be a double array.");
    }
    if (! mxIsDouble(LABELS_IN)) {
      mexErrMsgTxt("Second argument must be a double array.");
    }
    if (! mxIsLogical(MASK_IN)) {
      mexErrMsgTxt("Third argument must be a logical array.");
    }

    /* Create matrices for the return arguments */ 
    LABELS_OUT = mxCreateDoubleMatrix(m, n, mxREAL); 
    DISTANCES_OUT = mxCreateDoubleMatrix(m, n, mxREAL);
    DIFF_COUNT_OUT = mxCreateDoubleScalar(0);
    POP_COUNT_OUT = mxCreateDoubleScalar(0);
    
    /* Assign pointers to the various parameters */ 
    labels_in = mxGetPr(LABELS_IN);
    im_in = mxGetPr(IM_IN);
    mask_in = mxGetLogicals(MASK_IN);
    lambda = mxGetPr(LAMBDA_IN);

    intensity_refs = mxGetPr(INTENSITY_REF_IN);
    nlabel = mxGetM(INTENSITY_REF_IN);

    double * dptr = mxGetPr(RADIUS_IN);
    radius = (int) (*dptr);
    //dptr = mxGetPr(RADIUS_CENTER_IN);
    //radius_center = (int) (*dptr);
    
    labels_out = mxGetPr(LABELS_OUT);
    dists = mxGetPr(DISTANCES_OUT);
    difference_count = mxGetPr(DIFF_COUNT_OUT);
    pop_count = mxGetPr(POP_COUNT_OUT);    
    
    /* Do the actual computations in a subroutine */
    propagate(labels_in, im_in, mask_in, labels_out, dists, m, n, radius, intensity_refs, nlabel, *lambda); 
       
    if (nlhs <= 2) {
      mxDestroyArray(DIFF_COUNT_OUT);
      mxDestroyArray(POP_COUNT_OUT);
      if (nlhs == 1) {
        mxDestroyArray(DISTANCES_OUT);
      }
    }      

    return;
}
