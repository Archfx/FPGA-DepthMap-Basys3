/******************************************************************************/
/******************     Module for writing .bmp image    		 *************/
/******************************************************************************/
module image_write
#(parameter WIDTH 	= 320,							// Image width
			HEIGHT 	= 240,								// Image height
			INFILE  = "output.bmp",						// Output image
			BMP_HEADER_NUM = 54							// Header for bmp image
)
(
	input HCLK,												// Clock	
	input HRESETn,											// Reset active low
	input hsync,											// Hsync pulse						
    input [7:0]  DATA_WRITE_R0,						// Red 8-bit data (odd)
    input [7:0]  DATA_WRITE_G0,						// Green 8-bit data (odd)
    input [7:0]  DATA_WRITE_B0,						// Blue 8-bit data (odd)
    input [7:0]  DATA_WRITE_R1,						// Red 8-bit data (even)
    input [7:0]  DATA_WRITE_G1,						// Green 8-bit data (even)
    input [7:0]  DATA_WRITE_B1,						// Blue 8-bit data (even)
	output 	reg	 Write_Done
);	
integer BMP_header [0 : BMP_HEADER_NUM - 1];		// BMP header
reg [7:0] out_BMP  [0 : WIDTH*HEIGHT*3 - 1];		// Temporary memory for image
reg [18:0] data_count;									// Counting data
wire done;													// done flag
// counting variables
integer i;
integer k, l, m;
integer fd; 
//----------------------------------------------------------//
//-------Header data for bmp image--------------------------//
//----------------------------------------------------------//
// Windows BMP files begin with a 54-byte header: 
// Check the website to see the value of this header: http://www.fastgraph.com/help/bmp_header_format.html
initial begin
	BMP_header[ 0] = 66;BMP_header[28] =24;
	BMP_header[ 1] = 77;BMP_header[29] = 0;
	BMP_header[ 2] = 56;BMP_header[30] = 0;
	BMP_header[ 3] =  132;BMP_header[31] = 0;
	BMP_header[ 4] = 3;BMP_header[32] = 0;
	BMP_header[ 5] =  0;BMP_header[33] = 0;
	BMP_header[ 6] =  0;BMP_header[34] = 0;
	BMP_header[ 7] =  0;BMP_header[35] = 0;
	BMP_header[ 8] =  0;BMP_header[36] = 0;
	BMP_header[ 9] =  0;BMP_header[37] = 0;
	BMP_header[10] = 54;BMP_header[38] = 0;
	BMP_header[11] =  0;BMP_header[39] = 0;
	BMP_header[12] =  0;BMP_header[40] = 0;
	BMP_header[13] =  0;BMP_header[41] = 0;
	BMP_header[14] = 40;BMP_header[42] = 0;
	BMP_header[15] =  0;BMP_header[43] = 0;
	BMP_header[16] =  0;BMP_header[44] = 0;
	BMP_header[17] =  0;BMP_header[45] = 0;
	BMP_header[18] =  64;BMP_header[46] = 0;
	BMP_header[19] =  1;BMP_header[47] = 0;
	BMP_header[20] =  0;BMP_header[48] = 0;
	BMP_header[21] =  0;BMP_header[49] = 0;
	BMP_header[22] =  240;BMP_header[50] = 0;
	BMP_header[23] =  0;BMP_header[51] = 0;	
	BMP_header[24] =  0;BMP_header[52] = 0;
	BMP_header[25] =  0;BMP_header[53] = 0;
	BMP_header[26] =  1;
	BMP_header[27] =  0;
end
// row and column counting for temporary memory of image 
always@(posedge HCLK, negedge HRESETn) begin
    if(!HRESETn) begin
        l <= 0;
        m <= 0;
    end else begin
        if(hsync) begin
            if(m == WIDTH/2-1) begin
                m <= 0;
                l <= l + 1; // count to obtain row index of the out_BMP temporary memory to save image data
            end else begin
                m <= m + 1; // count to obtain column index of the out_BMP temporary memory to save image data
            end
        end
    end
end
// Writing RGB888 even and odd data to the temp memory
always@(posedge HCLK, negedge HRESETn) begin
    if(!HRESETn) begin
        for(k=0;k<WIDTH*HEIGHT*3;k=k+1) begin
            out_BMP[k] <= 0;
        end
    end else begin
        if(hsync) begin
            out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+2] <= DATA_WRITE_R0;
            out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+1] <= DATA_WRITE_G0;
            out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m  ] <= DATA_WRITE_B0;
            out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+5] <= DATA_WRITE_R1;
            out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+4] <= DATA_WRITE_G1;
            out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+3] <= DATA_WRITE_B1;
        end
    end
end
// data counting
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        data_count <= 0;
    end
    else begin
        if(hsync)
			data_count <= data_count + 1; // pixels counting for create done flag
    end
end
assign done = (data_count == 38399)? 1'b1: 1'b0; // done flag once all pixels were processed
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        Write_Done <= 0;
    end
    else begin
		Write_Done <= done;
    end
end
//---------------------------------------------------------//
//--------------Write .bmp file		----------------------//
//----------------------------------------------------------//
initial begin
    fd = $fopen(INFILE, "wb+");
end
always@(Write_Done) begin // once the processing was done, bmp image will be created
    if(Write_Done == 1'b1) begin
        for(i=0; i<BMP_HEADER_NUM; i=i+1) begin
            $fwrite(fd, "%c", BMP_header[i][7:0]); // write the header
        end
        
        for(i=0; i<WIDTH*HEIGHT*3; i=i+6) begin
		// write R0B0G0 and R1B1G1 (6 bytes) in a loop
            $fwrite(fd, "%c", out_BMP[i  ][7:0]);
            $fwrite(fd, "%c", out_BMP[i+1][7:0]);
            $fwrite(fd, "%c", out_BMP[i+2][7:0]);
            $fwrite(fd, "%c", out_BMP[i+3][7:0]);
            $fwrite(fd, "%c", out_BMP[i+4][7:0]);
            $fwrite(fd, "%c", out_BMP[i+5][7:0]);
        end
    end
end
endmodule