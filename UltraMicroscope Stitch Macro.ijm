// Preprocess and stitch light sheet z-stacks

// Author: 	Luke Hammond
// Cellular Imaging | Zuckerman Institute, Columbia University
// Date:	5th August 2020

// This macro updates the filenames for tiles in selected folders and stitches using -Grid stitching

// For processing SC datasets from ImspectorPro (Ultramicroscope II)
// Caution: Renames files for stitching, names are restored after stitching but be aware this will not occur if Fiji crashes or closed before complete.
// Mosaic size determined by last file name - assuming square brackets around tiles
// 		e.g. UltraII[00 x 00]_C00.ome


requires("1.52p");
run("Clear Results"); 
run("Close All");

#@ File[] Dirs(label="Select folders:", style="both")
//#@ Integer(label="Grid size X:", value = 5, style="spinner") Xtiles
//#@ Integer(label="Grid size Y:", value = 5, style="spinner") Ytiles
#@ Integer(label="Overlap:", value = 20, style="spinner") overlap

for (FolderNum=0; FolderNum<Dirs.length; FolderNum++) {
	inputdir=Dirs[FolderNum];
    if (File.exists(inputdir)) {
        if (File.isDirectory(inputdir)) {

        	// sort files
        	inputdir = inputdir + "/";
			files = getFileList(inputdir);	
			files = ImageFilesOnlyArray(files);		
			files = Array.sort( files );

			// Get tile information - Assumes 16-58-35_sc11_647_pt1_UltraII[00 x 00]_C00.ome
			
			//*** to avoid renaming of files it is possible to use {xx} and {yy} but must be careful when passing file_names to Grid Stitching
			lastfile = files[files.length-1];
			XY = split(lastfile, "[");
			XYarray = split(XY[1], "x");
			Xtiles = parseInt(substring(XYarray[0],0,2))+1;
			Ytiles = parseInt(substring(XYarray[1],1,3))+1;
			
			// rename files for stitching
			for(i=0; i<files.length; i++) {				
				a = File.rename(inputdir+ files[i], inputdir + "tile_"+(1000+i)+".tif");
			}

			//make dir for output
			File.makeDirectory(inputdir + "/Stitched");

			// Run stitching
			
			//print(Xtiles, Ytiles);
			run("Grid/Collection stitching", "type=[Grid: row-by-row] order=[Right & Down                ] grid_size_x="+Xtiles+" grid_size_y="+Ytiles+" tile_overlap="+overlap+" first_file_index_i=0 directory=["+inputdir+"] file_names=tile_1{iii}.tif output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
			
			// Save and close
			selectWindow("Fused");
			saveAs("Tiff", inputdir+ "/Stitched/Fused.tif");
			close("*");

			// Correct file names
			
			for(i=0; i<files.length; i++) {	
				a = File.rename(inputdir + "tile_"+(1000+i)+".tif", inputdir + files[i]);	
			}

			// Clean  up
			collectGarbage(50, 4);
        }
    }
}

function ImageFilesOnlyArray (arr) {
	//pass array from getFileList through this e.g. NEWARRAY = ImageFilesOnlyArray(NEWARRAY);
	setOption("ExpandableArrays", true);
	f=0;
	files = newArray;
	for (i = 0; i < arr.length; i++) {
		if(endsWith(arr[i], ".tif") || endsWith(arr[i], ".nd2") || endsWith(arr[i], ".LSM") || endsWith(arr[i], ".czi") || endsWith(arr[i], ".jpg") ) {   //if it's a tiff image add it to the new array
			files[f] = arr[i];
			f = f+1;
		}
	}
	arr = files;
	arr = Array.sort(arr);
	return arr;
}

function collectGarbage(slices, itr){
	setBatchMode(false);
	wait(1000);
	for(i=0; i<itr; i++){
		wait(50*slices);
		run("Collect Garbage");
		call("java.lang.System.gc");
		}
	setBatchMode(true);
}