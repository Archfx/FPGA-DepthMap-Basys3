
/******************************************************************************/
/******************  Module for processing image     **************/
/******************************************************************************/
//`include "parameter.v" 						// Include definition file
module disparity_generator
#(
  parameter WIDTH 	= 320, 					// Image width
			HEIGHT 	= 240, 						// Image height
//			INFILE_L  = "Tsukuba_L.hex", 	// image file
//			INFILE_R  = "Tsukuba_R.hex", 	// image file
			START_UP_DELAY = 100, 				// Delay during start up time
			HSYNC_DELAY = 160,					// Delay between HSYNC pulses	
			VALUE= 100								// value for Brightness operation
//			THRESHOLD= 90,							// Threshold value for Threshold operation
//			SIGN=0									// Sign value using for brightness operation
														// SIGN = 0: Brightness subtraction
														// SIGN = 1: Brightness addition
)
(
	input HCLK,										// clock
	input [3:0] left_in,
	input [3:0] right_in,	
	output [3:0]  dOUT,				// Disparity out (even)
    output [16:0]  dOUT_addr,				// Disparity out (even)	
    output [16:0]	left_right_addr,
//    output [16:0]   right_addr,
    output	reg		  ctrl_done,
    output reg offsetfound					// Done flag
    		
	
);			

reg 		ctrl_data_run;					// control signal for data processing


reg [0 : (WIDTH*HEIGHT - 1)*4] org_L; 	// temporary storage for Left image
reg [0 : (WIDTH*HEIGHT - 1)*4] org_R ;	// temporary storage for Right image

reg [8:0] row; // row index of the image
reg [8:0] col; // column index of the Left image
parameter window = 5;
integer x,y; // column index of the Right image
reg [3:0] offset, best_offset;//, best_offset_1;
localparam [4:0] maxoffset = 10; // Maximum extent where to look for the same pixel
reg offsetfound;
reg offsetping;
reg compare;
reg [20:0] ssd;//, ssd_1; // sum of squared difference
reg [20:0] prev_ssd;//, prev_ssd_1;
reg [16:0] data_count; // data counting for entire pixels of the image
reg [16:0] readreg;
reg doneFetch;

assign dOUT_addr= data_count;
assign left_right_addr=readreg;
assign dOUT=best_offset;

always@(posedge HCLK) begin
    if (~doneFetch) begin
        if (readreg<76800) begin
           org_L[readreg*4+:4]<= left_in;
           org_R[readreg*4+:4]<= right_in;
           readreg=readreg+1;
        end
        else begin
            readreg <= 0;
            doneFetch <=1;
        end
    end
    
    //2
    if(ctrl_done) begin
        data_count <= 0;
    end
    else begin
        if(ctrl_data_run)
			data_count <= data_count + 1;
    end
    
    ctrl_done <= (data_count == 308487)? 1'b1: 1'b0; // done flag308472
    if (ctrl_done) doneFetch=0;
    
    //2
    
    //3
    
    if (offsetfound) begin
        offset <= 4'd4;
    end
    //3
    
    //4
    if (offsetping) begin
        for(x=-(window-1)/2; x<((window-1)/2)+1; x=x+1) begin
			for(y=-(window-1)/2; y<((window-1)/2)+1; y=y+1) begin
				ssd=ssd+(org_L[((row + x ) * WIDTH + col + y)*4  +:4   ]-org_R[((row + x ) * WIDTH + col + y -offset)*4 +:4 ])*(org_L[((row +  x ) * WIDTH + col + y )*4 +:4   ]-org_R[((row +  x ) * WIDTH + col + y - offset)*4 +:4 ]);
//				ssd_1=ssd_1+(org_L[(row + x ) * WIDTH + col + y  + 1 ]-org_R[(row + x ) * WIDTH + col + y -offset + 1 ])*(org_L[(row +  x ) * WIDTH + col + y  + 1 ]-org_R[(row +  x ) * WIDTH + col + y - offset + 1 ]);
			end
	   end
	
	   compare<=1;
    end
    
    //4
    
    //5
    if (compare) begin
        if (ssd < prev_ssd ) begin
            prev_ssd<=ssd;
            best_offset<=offset;
            
        end
	

	
	
	   offsetping<=0;
	   compare<=0;
    end
    //5
    
    //6
    if (doneFetch) begin
        if(ctrl_done) begin
            row <= 0;
              col<= 0;
              offset<=4'd4;
              offsetping<=0;
              compare<=0;
              ctrl_done <= 0;
              
        end
        else begin
            
            if(ctrl_data_run & offsetping==0 & compare==0) begin
                if (offsetfound) begin
                    if(col == WIDTH - 1) begin
                        row <= row + 1;
                        
                    end
                    if(col == WIDTH - 1) begin
                        col <= 0;		
                    end
                    else begin 
                        col <= col + 1; // reading 2 pixels in parallel
                    end
                    offsetfound <= 0;
                    best_offset <= 0;
                    prev_ssd <= 21'd65535;
    //				best_offset_1 <= 0;
    //				prev_ssd_1 <= 65535;
                end
                else begin
                    if(offset==maxoffset) begin
                        offsetfound <= 1;
                    end
                    else begin
                            offset<=offset+1;
                        //$display("row %d col %d  offset %d",row,col,offset);
                    end
                    ssd<=0;
    //				ssd_1<=0;
                    offsetping<=1;
            end
                
            
        end
end
end
    //6
    
end


//always@(posedge HCLK,posedge doneFetch)
//begin
//if (doneFetch) begin
//    if(ctrl_done) begin
//        row <= 0;
//		  col<= 0;
//		  offset<=4'd4;
//		  offsetping<=0;
//		  compare<=0;
//		  ctrl_done <= 0;
		  
//    end
//	else begin
		
//		if(ctrl_data_run & offsetping==0 & compare==0) begin
//			if (offsetfound) begin
//				if(col == WIDTH - 1) begin
//					row <= row + 1;
					
//				end
//				if(col == WIDTH - 1) begin
//					col <= 0;		
//				end
//				else begin 
//					col <= col + 1; // reading 2 pixels in parallel
//				end
//				offsetfound <= 0;
//				best_offset <= 0;
//				prev_ssd <= 21'd65535;
////				best_offset_1 <= 0;
////				prev_ssd_1 <= 65535;
//			end
//			else begin
//				if(offset==maxoffset) begin
//					offsetfound <= 1;
//				end
//				else begin
//						offset<=offset+1;
//					//$display("row %d col %d  offset %d",row,col,offset);
//				end
//				ssd<=0;
////				ssd_1<=0;
//				offsetping<=1;
//		end
			
		
//	end
//end
//end
//end
//always@(posedge offsetping) begin
//	for(x=-(window-1)/2; x<((window-1)/2)+1; x=x+1) begin
//			for(y=-(window-1)/2; y<((window-1)/2)+1; y=y+1) begin
//				ssd=ssd+(org_L[((row + x ) * WIDTH + col + y)*4  +:4   ]-org_R[((row + x ) * WIDTH + col + y -offset)*4 +:4 ])*(org_L[((row +  x ) * WIDTH + col + y )*4 +:4   ]-org_R[((row +  x ) * WIDTH + col + y - offset)*4 +:4 ]);
////				ssd_1=ssd_1+(org_L[(row + x ) * WIDTH + col + y  + 1 ]-org_R[(row + x ) * WIDTH + col + y -offset + 1 ])*(org_L[(row +  x ) * WIDTH + col + y  + 1 ]-org_R[(row +  x ) * WIDTH + col + y - offset + 1 ]);
//			end
//	end
	
//	compare<=1;
//end

//always @(posedge compare) begin	

//	if (ssd < prev_ssd ) begin
//		prev_ssd<=ssd;
//		best_offset<=offset;
		
//	end
	

	
	
//	offsetping<=0;
//	compare<=0;
	
//end

//always@(posedge offsetfound) begin
////	dOUT<=best_offset;
//////	DATA_1_L =best_offset_1*(255/maxoffset);
////	//DATA_0_L=(org_L[WIDTH * row + col  ]+org_R[WIDTH * row + col  ])/2 ;
////	//DATA_1_L =(org_L[WIDTH * row + col+1  ]+org_R[WIDTH * row + col+1  ])/2;
//	offset <= 4'd4;
//end


//////-------------------------------------------------//
//////----------------Data counting---------- ---------//
//////-------------------------------------------------//
//always@(posedge HCLK)
//begin
//    if(ctrl_done) begin
//        data_count <= 0;
//    end
//    else begin
//        if(ctrl_data_run)
//			data_count <= data_count + 1;
//    end
    
//    ctrl_done <= (data_count == 308487)? 1'b1: 1'b0; // done flag308472
//    if (ctrl_done) doneFetch=0;
//end
////assign VSYNC = ctrl_vsync_run;

////-------------------------------------------------//
////-------------  Image processing   ---------------//
////-------------------------------------------------//
////always @(*) begin
	
////	HSYNC   = 1'b0;
//////	DATA_0_L = 0;
////	dOUT = 0;
//////	DATA_0_R = 0;                                       
//////	DATA_1_R = 0;
                                       
////	if(ctrl_data_run) begin
////		if (offsetfound) HSYNC   = 1'b1;
////		else HSYNC   = 1'b0;
		
////	end
////end

endmodule

