/**
* Name: prototype
* Based on the internal empty template. 
* Author: Charles Cordial
* Tags: Base Scenario (Two Block Layout, No mask variation, 40 students)
*/


model experiment1

/* Insert your model definition here */

global{
// Dimension of the grid m_bar be the number of rows and n_bar be the number of columns
	float m_bar <- 36;
	float n_bar <- 28;
	
//	Size of Classroom
	geometry shape <- rectangle(7#m,9#m);
		
		
//	Facility Size Lower and Upper Bound 
	float L_x <- 0.0; float U_x <- n_bar - 1;
	float L_y <- 0.0; float U_y <- m_bar - 1;
	
//  Number of Susceptible agents
	int nb_susceptible_init <- 39;
//	Number of Infected agents
	int nb_infected_init <- 1;
//	Initial number of agents and infected individuals
	int population <- nb_susceptible_init + nb_infected_init;
	
//  Initial number of recovered agents
	int nb_recovered_agents	<- 0;
//	Probability of coughing
	float prob_cough <- 0.61;
//	Probability of infecting
	float prob_infect <- 0;

//	maxiteration
	int maxiter <- 500;


//	Number of Infected people and Number of Healthy People
	int nb_people_infected <- nb_infected_init update: people count (each.is_infected);
	int nb_people_not_infected <- population - nb_infected_init update: population  - nb_people_infected;
	float num_newly_infect <- 0.0;
	float infected_rate update: nb_people_infected/(nb_people_infected + nb_people_not_infected);
	

// Normalized B
	float B_k <- 0.0 update: nb_people_infected / (nb_people_not_infected + nb_people_infected);
	float k_N <- 0.0 update: time / maxiter;
	float J_function <- 0.0 update: B_k - k_N;	
	

// Clock and timestep
	date my_date <- date("2023-02-01-08-00-00");
	float step <- 15 #mn;
	int nb_day <- 1;
	
	init{
			
		create people from:csv_file( "../includes/twoblock.csv",true) with:
			[grid_x::int(get("gridx")), 
				grid_y::int(get("gridy")), 
				state::string(get("state"))
			];	

		ask nb_infected_init among people{
			state <- "Infected Contagious";
			num_day_infected <- 5;
			is_infected <- true;
			agent_color <- #red;
		} 
		
	}
	
	reflex print_iteration{
		write("");
		write("Iteration: " + cycle);
	}
	reflex update_time{
			my_date <- my_date plus_minutes 15;
	}
	
   	bool check <- false;
	reflex cal_day {
		if (((my_date.hour != 0) and (my_date.hour mod 9 = 0))  and !check) {
			nb_day <- nb_day + 1;
			check <- true;
			my_date <- my_date plus_hours 15;
//			Update number of days infected for a particular infected individual
			loop i over: people{
				if(i.is_infected){
					i.num_day_infected <- i.num_day_infected + 1;
				}
			}
			num_newly_infect <- 0;
//			Update number of newly infected individuals per day
			loop i over: people{
				if(i.num_day_infected = 1){
					num_newly_infect <- num_newly_infect + 1;
				}
			}
		}
		if (current_date.hour mod 9 = 1) {
			check <- false;
		}
	}
	
	reflex count_recovered{
		int count <- 0;
		loop i over: people{
			if (i.agent_color = #green){
				count <- count + 1;
			}
		}
		nb_recovered_agents <- count;
	}
	
	
//	cycle = 1 or cycle = 10 or cycle = 50 or cycle = 150 or cycle = 200 or cycle = 300 or infected_rate > 0.98
//	infected_rate > 0.98  time = 1 or time = 10 or time = 50 or time = 150 or time = 200 or time = 250 or time = 300
	reflex end_simulation when: cycle = 8000 {
		do pause;
    }	
    
//    reflex extract_data_jfunction{
//    	save [cycle, nb_people_infected, J_function ,B_k] to: name + "j_function.csv" type: csv rewrite: (cycle = 0) ? true : false;	
// 
//    }

	
	


}


species people skills:[moving]{		
	grid_cell my_cell;
	int grid_x;
	int grid_y;
	string state;
	rgb agent_color <- #blue;
	bool is_infected <- false;
	bool is_alive <- true;
	int num_day_infected <- 0;
	date date_got_infected;
	

	init{		
		my_cell <- initialize_seat(self);
		location <- my_cell.location;
	}
	
	
	reflex update_state	when: is_infected{		
		if(num_day_infected >= 5 and num_day_infected < 14){
			state <- "Infected Contagious";
			agent_color <- #red;
		}
		if(num_day_infected >= 14){
			state <- "Recovered";
			is_infected <- false;
			agent_color <- #green;
		}
	}
	
	
	
	reflex cough when: is_infected and (state = "Infected Contagious"){
		float r <- rnd(0.00,1.00, 0.01);
		if(r <= prob_cough){
			write("Cough Performed by: " + self);
			if(state = "Infected Contagious"){
				ask people at_distance 1#m {
					if(!self.is_infected and self.agent_color = #blue){
						float distance_between <- self distance_to myself;
						write("");
						write("Infected " + myself);
						write ("Susceptible " + self);
						
						write("Distance: " + distance_between);
						if((distance_between >= 0) and (distance_between <= 0.25)){
							 prob_infect <- 0.61;
						}
						if((distance_between > 0.25) and (distance_between <= 0.50)){
							 prob_infect <- 0.55;
						}
						if((distance_between > 0.50) and (distance_between <= 0.75)){
							 prob_infect <- 0.38;
						}
						if((distance_between > 0.75) and (distance_between <= 1.00)){
							 prob_infect <- 0.15;
						}
//						if(distance_between > 1){
//							 prob_infect <- 0.03;
//						}
						float r <- rnd(0.00,1.00, 0.01);
						write("Prob_infect value: " + prob_infect);
						write("Random Number Generated: " + r);
						if(r <= prob_infect){
							self.is_infected <- true;
							self.state <- "Infected Non-Contagious";
							self.agent_color <- #orange;
							self.date_got_infected <- my_date;
							write("Agent "+myself+ " infects agent "+self);		
						}
						else{
							write("No infection happened");
						}
					}
				}
			}
		}
	}
		
		
	bool move <- false;
	reflex basic_move {
		if(((my_date.hour = 2) and (my_date.minute = 0)) or ((my_date.hour = 4) and (my_date.minute = 0))){
			move <- true;
		}
		if(((my_date.hour = 2) and (my_date.minute = 30)) or ((my_date.hour = 5) and (my_date.minute = 0)) ){
			move <- false;
			my_cell <- go_back_seat();
			location <- my_cell.location;
		}		
		if(move){
			my_cell <- random_distance_movement();
			location <- my_cell.location;
		}	
	}
	
	grid_cell random_distance_movement {
		float x_j <- L_x + round(float(rnd(0.0,1.0,0.01)) * U_x);
		float y_j <- L_y + round(float(rnd(0.0,1.0,0.01)) * U_y);
		
		my_cell <- grid_cell grid_at {x_j, y_j};
		list<people> people_inside <- people inside (my_cell);
		if(length(people_inside) > 0){
			write(self.name);
			write "Choose another cell";
			my_cell <- random_distance_movement();
		}
		else{
			write(self.name);
			write "just perform Random Distance Movement";
			return my_cell;
		}
	}
	
	
	grid_cell initialize_seat(people wew){
		my_cell <- grid_cell grid_at {wew.grid_x, wew.grid_y};
		return my_cell;
	}
	
	grid_cell go_back_seat{
		my_cell <- grid_cell grid_at {self.grid_x, self.grid_y};
		return my_cell;
	}
	
	

    aspect circle {
		draw circle(0.1#m) color: agent_color;
	}
	
	aspect name {
        draw name size: 3 color: #black ;
    }
    
    aspect num_day_infect {
    	draw string(num_day_infected) size: 2 color: #white;
    }
}



grid grid_cell cell_width: 0.25#m cell_height: 0.25#m neighbors: 8 {
	list<grid_cell> neighbors1 <- (self neighbors_at 1);
}


//experiment experiment1 type: batch repeat: 2 until: (cycle = 100 or infected_rate = 0.60)
experiment experiment1 type: gui{

	output {
		monitor "Current Hour" value: my_date.hour;
		monitor "Date" value: my_date;	
		monitor "Day Counter" value: nb_day;
		monitor "m_bar(rows)" value: m_bar;
		monitor "n_bar(columns)" value: n_bar;
		monitor "Total Population" value: population;
		monitor "Initial Number of Susceptible" value: nb_susceptible_init;
		monitor "Initial Number of Infected" value: nb_infected_init;
		monitor "Infected Rate" value: infected_rate;
		monitor "Number of Newly Infected People" value: num_newly_infect;
		monitor "Number of Infected People" value: nb_people_infected;
		monitor "Number of Healthy People" value: nb_people_not_infected;
		monitor "Number of Recovered People" value: nb_recovered_agents;
		
		
		
		display main_display {
			grid grid_cell lines: #black;
			species people aspect:circle;
		}
		display info_display{
			grid grid_cell lines: #black;
			species people aspect: circle;
			species people aspect: name;
			species people aspect: num_day_infect;
			
		}
//		display SI_graph refresh: every(1 #cycles) {
//			chart "SI Graph" type: series {
//				data "Number of susceptible" value: nb_people_not_infected color: #green;
//				data "Number of infected" value: nb_people_infected color: #red;
//			}
//		}
//		display Bk refresh: every(1 #cycles) {
//			chart "B Graph" type: series {
//				data "|B_k|" value: nb_people_infected color: #black;
//			}
//		}
//		display Cost_Function_Graph refresh: every(1 #cycles) {
//			chart "Cost Function Graph" type: series {
//				data "J" value: J_function color: #black;
//			}
//		}
	}
}