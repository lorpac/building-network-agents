/***
* Name: BuildingNetModel
* Author: Lorenza
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BuildingNetModel

/* Insert your model definition here */

global {
	float step <- 1 #mn;
	
	string simulation_name;
	bool merged;
	file buildings_shapefile;
	file empty_space_shapefile;
	int num_cycles <- 5000;
	int number_of_pedestrians <- 50;
	int grid_resolution <- 100;
	float restart_probability <- 0.05;
	list parameters <- ["simulation_name: ", simulation_name,
		"\nnum_cycles: ", string(num_cycles),
		"\nnumber_of_pedestrians: ", string(number_of_pedestrians),
		"\ngrid_resolution: ", string(grid_resolution),
		"\nrestart_probability: ", string(restart_probability)
	]; 
	
	
	
	geometry total_shape <- envelope(buildings_shapefile);
	geometry shape <- total_shape;
	
	init {
		create building from: buildings_shapefile ;
		create empty_space from: empty_space_shapefile ;
		create pedestrian number: number_of_pedestrians ;
	}
	
	reflex halting when: cycle = num_cycles {
		if merged {
			save cell_time_inside to: "results/" + simulation_name + "/" + simulation_name + "-mean-exit-time.csv" type: "csv";
			save parameters to: "results/" + simulation_name + "/" + simulation_name + "-parameters.csv" type: "csv";
		}
		else {
			save cell_time_inside to: "results/" + simulation_name + "_not_merged/" + simulation_name + "-mean-exit-time.csv" type: "csv";
			save parameters to: "results/" + simulation_name + "_not_merged/" + simulation_name + "-parameters.csv" type: "csv";
		}
		
        do pause;
    }
	
	
}

species building {
	string type; 
	rgb color <- #gray  ;
	aspect base {
		draw shape color: color ;
	}
}


species empty_space{
	rgb color <- #red  ;
	aspect base {
		draw shape color: color border: #black;
	}
}


species pedestrian skills:[moving]{
//	point target;
	geometry available_space;
	bool too_close <- false;
	point last_position;
	
	init {
    speed <- 3 #km/#h;
    ask empty_space {
    		myself.available_space  <- self.shape;
    	}
    location <- any_location_in(available_space);
    heading <- rnd(-180.0, 180.0);
    last_position <- location;
    }
    
    reflex change_heading when: last_position = location {
    	heading <- rnd(-180.0, 180.0);
    }    
    
    reflex move{
    	last_position <- location;
    	do move (bounds: available_space);
    }
    
    reflex restart when: flip(restart_probability){
    	location <- any_location_in(available_space);
    }


    aspect base {
    draw circle(10) color:#green border: #black;
    }
}

grid cell_presence width: grid_resolution height: grid_resolution {
    int number_presences <- 0;
    list<pedestrian> pedestrian_inside -> {pedestrian inside self};
    
    action update_count_presences {
    	number_presences <- number_presences + length(pedestrian_inside);
    }
    
    list<rgb> colors_presences <- brewer_colors("YlOrRd", 13);
    
    action update_color_presences {
    if (number_presences = 0) {
        color <- rgb(#white);
    } else if (number_presences < length(colors_presences)) {
        color <- colors_presences at number_presences;
    } else {
        color <- colors_presences at (length(colors_presences) -1);
    }
    }
    
    
    reflex update {
    	do update_count_presences;
    	do update_color_presences;
    }
    
}



grid cell_time_inside width: grid_resolution height: grid_resolution {
    int number_presences <- 0;
    list<pedestrian> pedestrian_inside_before <- [];
    list<pedestrian> pedestrian_exited <- [];
    list<pedestrian> pedestrian_inside -> {pedestrian inside self};
    map<pedestrian, int> time_inside <- [];
    list<int> exit_time <- [];
    int visitors <- 0;
    float mean_exit_time ;
    rgb color_exit_time ;

    action update_average_exit_time{
    	loop i over: pedestrian_inside {
			if (i in pedestrian_inside_before){
				time_inside[i] <- time_inside[i] + 1;
			}
			else {
				time_inside <+ i::1;
			}
		}
		loop i over: pedestrian_exited {
			add time_inside at i to: exit_time ;
			remove key: i from: time_inside;
		}
		mean_exit_time <- mean(exit_time);
    }
    
    list<rgb> colors_exit_time <- brewer_colors("Reds", 10);
    
    action update_color_exit_time {
//    if (mean_exit_time > 0){
	    if (mean_exit_time < length(colors_exit_time)) {
	        color <- colors_exit_time at int(mean_exit_time);
	    } else {
	        color <- colors_exit_time at (length(colors_exit_time) -1);
	    }    	
//    }

    }
    
    reflex update {
    	pedestrian_exited <- pedestrian_inside_before - pedestrian_inside;
    	do update_average_exit_time;
    	do update_color_exit_time;
    	pedestrian_inside_before <- copy(pedestrian_inside);
    }
}


experiment Manhattan type: gui{
	
	parameter "Simulation name" var:simulation_name <- "Manhattan_2020_11_12";
	parameter "Merged" var:merged <- true;
	parameter "Full shape file" var:buildings_shapefile <- file("../includes/" + simulation_name +"merged_buildings.shp");
	parameter "Empty shape file" var:empty_space_shapefile <- file("../includes/" + simulation_name +"merged_buildings_empty.shp");
	parameter "N. pedestrians" var:number_of_pedestrians;
	parameter "Number of cycles" var:num_cycles;
	parameter "Grid resolution" var:grid_resolution;
	parameter "Restart probability" var:restart_probability;
	
	
	output {
		display display1 name: "Presence" autosave: true {
			grid cell_presence ;
			species building aspect: base ;
			image gis:"../includes/" + simulation_name + "buildingsOSM.shp" color: rgb('black');
			species pedestrian aspect:base;
		}
		display display2 name: "Mean exit time" autosave: true {
			grid cell_time_inside ;
			species building aspect: base ;
			image gis:"../includes/" + simulation_name + "buildingsOSM.shp" color: rgb('black');
			species pedestrian aspect:base;
		}
	}
}

experiment Monplaisir type: gui{
	
	parameter "Simulation name" var:simulation_name <- "Monplaisir_2020_11_12";
	parameter "Merged" var:merged <- true;
	parameter "Full shape file" var:buildings_shapefile <- file("../includes/" + simulation_name +"merged_buildings.shp");
	parameter "Empty shape file" var:empty_space_shapefile <- file("../includes/" + simulation_name +"merged_buildings_empty.shp");
	parameter "N. pedestrians" var:number_of_pedestrians;
	parameter "Number of cycles" var:num_cycles;
	parameter "Grid resolution" var:grid_resolution;
	parameter "Restart probability" var:restart_probability;
	
	
	output {
		display display1 name: "Presence" autosave: true {
			grid cell_presence ;
			species building aspect: base ;
			image gis:"../includes/" + simulation_name + "buildingsOSM.shp" color: rgb('black');
			species pedestrian aspect:base;
		}
		display display2 name: "Mean exit time" autosave: true {
			grid cell_time_inside ;
			species building aspect: base ;
			image gis:"../includes/" + simulation_name + "buildingsOSM.shp" color: rgb('black');
			species pedestrian aspect:base;
		}
	}
}

experiment Charpennes type: gui{
	
	parameter "Simulation name" var:simulation_name <- "Charpennes_2020_11_12";
	parameter "Merged" var:merged <- true;
	parameter "Full shape file" var:buildings_shapefile <- file("../includes/" + simulation_name +"merged_buildings.shp");
	parameter "Empty shape file" var:empty_space_shapefile <- file("../includes/" + simulation_name +"merged_buildings_empty.shp");
	parameter "N. pedestrians" var:number_of_pedestrians;
	parameter "Number of cycles" var:num_cycles;
	parameter "Grid resolution" var:grid_resolution;
	parameter "Restart probability" var:restart_probability;
	
	
	output {
		display display1 name: "Presence" autosave: true {
			grid cell_presence ;
			species building aspect: base ;
			image gis:"../includes/" + simulation_name + "buildingsOSM.shp" color: rgb('black');
			species pedestrian aspect:base;
		}
		display display2 name: "Mean exit time" autosave: true {
			grid cell_time_inside ;
			species building aspect: base ;
			image gis:"../includes/" + simulation_name + "buildingsOSM.shp" color: rgb('black');
			species pedestrian aspect:base;
		}
	}
}

//experiment Lyon_center type: gui{
//	
//	parameter "Simulation name" var:simulation_name <- "Lyon_city_center_2021_1_29";
//	parameter "Merged" var:merged <- true;
//	parameter "Full shape file" var:buildings_shapefile <- file("../includes/" + simulation_name +"merged_buildings.shp");
//	parameter "Empty shape file" var:empty_space_shapefile <- file("../includes/" + simulation_name +"merged_buildings_empty.shp");
//	parameter "N. pedestrians" var:number_of_pedestrians;
//	parameter "Number of cycles" var:num_cycles;
//	parameter "Grid resolution" var:grid_resolution;
//	parameter "Restart probability" var:restart_probability;
//	
//	
//	output {
//		display display1 name: "Presence" autosave: true {
//			grid cell_presence ;
//			species building aspect: base ;
//			image gis:"../includes/" + simulation_name + "buildingsOSM.shp" color: rgb('black');
//			species pedestrian aspect:base;
//		}
//		display display2 name: "Mean exit time" autosave: true {
//			grid cell_time_inside ;
//			species building aspect: base ;
//			image gis:"../includes/" + simulation_name + "buildingsOSM.shp" color: rgb('black');
//			species pedestrian aspect:base;
//		}
//	}
//}
//
//experiment Lyon_center_not_merged type: gui{
//	string simulation_name <- "Lyon_city_center_2021_1_29";
//	parameter "Simulation name" var:simulation_name <- simulation_name;
//	parameter "Merged" var:merged <- false;
//	parameter "Full shape file" var:buildings_shapefile <- file("../includes/" + simulation_name +"buildingsOSM.shp");
//	parameter "Empty shape file" var:empty_space_shapefile <- file("../includes/" + simulation_name +"buildingsOSM_empty.shp");
//	parameter "N. pedestrians" var:number_of_pedestrians;
//	parameter "Number of cycles" var:num_cycles;
//	parameter "Grid resolution" var:grid_resolution;
//	parameter "Restart probability" var:restart_probability;
//	
//	
//	output {
//		display display1 name: "Presence" autosave: true {
//			grid cell_presence ;
//			species building aspect: base ;
//			species pedestrian aspect:base;
//		}
//		display display2 name: "Mean exit time" autosave: true {
//			grid cell_time_inside ;
//			species building aspect: base ;
//			species pedestrian aspect:base;
//		}
//	}
//}
