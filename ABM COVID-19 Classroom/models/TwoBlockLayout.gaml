model TwoBlockLayout
global{
	float width_size <- 7.0;	//	Size of Classroom
	float length_size <- 9.0;
	float grid_cell_length <- 0.25;
	geometry shape <- rectangle(width_size#m,length_size#m);
	int nb_susceptible_init <- 39;	//	Initial number of Susceptible agents
	int nb_infected_init <- 1;	//	Initial number of Infected agents
	int nb_recovered_people_init <- 0;	//	Initial number of Recovered agents
	int population <- nb_susceptible_init + nb_infected_init;	//	Total Populaton
	// Updating number of agents per compartment
	int nb_infected_people <- nb_infected_init update: people count (each.agent_color = #red or each.agent_color = #orange);
	int nb_susceptible_people <- nb_susceptible_init update: people count (each.agent_color = #blue);
	int nb_recovered_people <- nb_recovered_people_init update: people count (each.agent_color = #green);
	float num_newly_infect <- 0.0;
	float prev_num_newly_infect <- 0;
	float prob_cough <- 0.61;	//	Probability of Coughing parameter
	float rad_infect <- 1;	//	Radius of Infection parameter
	float prob_infect <- 0;	//	Probability of Infection from Cough parameter
	float increase <- 0;	//	Percentage increase for prob_infect
	float increase_prob_cough <- 0;	//	Percentage increase for prob_cough
	int maxiter <- 2000;	//	Maximum Number of Iteration
	float multiplier <- 0;	// 	prob_infect multiplier for scenarios
	bool vaccinated <- false;	// 	Scenarios Booleans
	bool eat_healthy <- false;
	bool comorb <- false;
	bool micro_nut_deficiency <- false;
	date my_date <- date("2023-02-01-08-00-00");	//	Global Clock and Timestep
	float step <- 15 #mn;
	int nb_day <- 1;
	init{	
		if(vaccinated){	//	Multiplier values for each scenario												
			multiplier <- -0.91;
		}
		if (eat_healthy){
			multiplier <- -0.1;
		}
		if(comorb){
			multiplier <- 0.5;
		}
		create people from:csv_file( "../includes/twoblock.csv",true) with:	//	Other files for Seat Distance Sensitivity Analysis: twoblock_min_20 | twoblock_min_10 | twoblock_min_5 | twoblock | twoblock_plus_5 | twoblock_plus_10 | twoblock_plus_20
			[grid_x::float(get("gridx")),	//	Initialization of Susceptible, Infected, and Recovered Agents
				grid_y::float(get("gridy")), 
				state::string(get("state"))
			];	

		ask nb_infected_people among people{
			state <- "Infected Contagious";
			num_day_infected <- 5;
			is_infected <- true;
			agent_color <- #red;
		} 	
	}
	reflex print_iteration{	//	Iteration number printer
		write("");
		write("Iteration: " + cycle);
	}
	reflex update_time{
			my_date <- my_date plus_minutes 15;	//	Increment real time per iteration
	}
   	bool check <- false;
	reflex cal_day {	//	Increment current day every 36 iteration
		if (((my_date.hour != 0) and (my_date.hour mod 9 = 0))  and !check) {
			nb_day <- nb_day + 1;
			check <- true;
			my_date <- my_date plus_hours 15;
			loop i over: people{	//	Update number of days infected for all infected agents
				if(i.is_infected){
					i.num_day_infected <- i.num_day_infected + 1;
				}
			}
			prev_num_newly_infect <- num_newly_infect;
			num_newly_infect <- 0;
			loop i over: people{
				if(i.num_day_infected = 1){	// 	Update number of newly infected individuals per day
					num_newly_infect <- num_newly_infect + 1;
				}
			}
		}
		if (current_date.hour mod 9 = 1) {
			check <- false;
		}
	}
	reflex end_simulation when: cycle = maxiter {	// 	Simulation ends at iteration 2000						
		do pause;
    }	
    reflex extract_output_data{	//	Record current number of SIR for each iteration in a csv file
    	save [increase_prob_cough ,increase, nb_day,cycle, nb_susceptible_people, nb_infected_people,  nb_recovered_people, num_newly_infect, vaccinated, eat_healthy, comorb, micro_nut_deficiency] to: name + "_Experiment_1.csv" type: csv rewrite: (cycle = 0) ? true : false;	
    }	
	bool move <- false;
	reflex move_agents{	//	Moving Behavior for all agents
		loop i over: people{
			if(((my_date.hour = 2) and (my_date.minute = 15)) or ((my_date.hour = 4) and (my_date.minute = 15))){
				move <- true;
			}
			if(((my_date.hour = 2) and (my_date.minute = 45)) or ((my_date.hour = 5) and (my_date.minute = 15)) ){
				move <- false;
				i.location <- {i.grid_x, i.grid_y};
			}		
			if(move){
				i.location <- any_location_in(shape);		
			}	
		}
	}
}
species people skills:[moving]{	//	Defining agents' attributes and actions
	float grid_x;	// 	Coordinates of the initial positions of an agent
	float grid_y;
	string state;
	rgb agent_color <- #blue;	//	Agents' color based on infection status
	bool is_infected <- false;	// 	Infection status							
	int num_day_infected <- 0;	// 	Agents' number of day infected
	date date_got_infected;	//	Date when an agent got infected
	init{		
		location <- {grid_x,grid_y};	//	Initialize agents' locations
	}
	reflex update_state	when: is_infected{	//	Update infection status: noncontagious -> contagious -> recovered
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
	reflex cough when: is_infected and (state = "Infected Contagious"){	//	2-layer threshold Infection Behavior using prob_cough and prob_infect
		float r <- rnd(0.00,1.00, 0.01);
		if(r <= ((prob_cough*increase_prob_cough) + prob_cough)){	//	increase_prob_cough is for the Sensitivity Analysis
			write("Cough Performed by: " + self);
			if(state = "Infected Contagious"){
				ask people at_distance rad_infect#m {	//	Loop over all susceptible agents within 1 meter radius of infected agent
					if(!self.is_infected and self.agent_color = #blue){
						float distance_between <- self distance_to myself;	//	Calculate distance between actor(infected agent) and susceptible agent
						write("");
						write("Infected " + myself);
						write ("Susceptible " + self);		
						write("Distance: " + distance_between);		
						if((distance_between >= 0) and (distance_between <= 0.25)){	//	prob_infect values depending on the distance of the two agents
							 prob_infect <- 0.61;							
						}
						if((distance_between > 0.25) and (distance_between <= 0.50)){
							 prob_infect <- 0.55;							
						}
						if((distance_between > 0.50) and (distance_between <= 0.75)){
							 prob_infect <- 0.38;							 
						}
						if((distance_between > 0.75) and (distance_between < 1.00)){
							 prob_infect <- 0.15;						
						}
						if(distance_between >= 1){
							 prob_infect <- 0.03;
						}
						prob_infect <- (prob_infect * multiplier) + prob_infect;	//	Different Prob_infect values for each scenario
						prob_infect <- (prob_infect * increase) + prob_infect;	//	For Sensitivity Analysis | Experimental cases (i.e 20% increase)
						float r <- rnd(0.00,1.00, 0.01);
						write("Prob_infect value: " + prob_infect);
						write("Random Number Generated: " + r);
						if(r <= prob_infect){	//	Checker if an agent got infected from the cough
							self.is_infected <- true;
							self.state <- "Infected Non-Contagious";
							self.agent_color <- #red;	//	Can use color orange to make noncontagious distinct
							self.date_got_infected <- my_date;
							write("Agent "+myself+ " infects agent "+self);		
						}
						else{	//	No infection happenned 
							write("No infection happened");
						}
					}
				}
			}
		}
	}
    aspect circle {	//	Agents representation in the model: 0.125 meter radius
		draw circle(0.125#m) color: agent_color; 
	}
	aspect name {	//	Displays name of an agent in the simulation
        draw name size: 3 color: #black ;
    }
    aspect num_day_infect {
    	draw string(num_day_infected) size: 2 color: #white;	//	Displays number of days an agent got infected
    }
}
grid grid_cell cell_width: 0.25#m cell_height: 0.25#m neighbors: 8 {	//	Initialize grid
	list<grid_cell> neighbors1 <- (self neighbors_at 1);
}
experiment explore_increase_prob_cough type: batch repeat: 10 until: cycle = 2000{	//	OFAT Sensitivity Analysis values for prob_cough, Experimental cases values (-20%, -10%, -5%, 0%, 5%, 10%, 20%) 
	parameter "increase_prob_cough" var: increase_prob_cough among: [-0.20,-0.10,-0.05, 0, 0.05, 0.10, 0.20];
		output {
	}	
}
experiment explore_increase_prob_infect type: batch repeat: 10 until: cycle = 2000{	//	OFAT Sensitivity Analysis values for prob_infect, Experimental cases values (-20%, -10%, -5%, 0%, 5%, 10%, 20%)
	parameter "increase" var: increase among: [-0.20,-0.10,-0.05, 0, 0.05, 0.10, 0.20];
		output {
	}	
}
experiment TwoBlockLayout type: batch repeat: 10 until: (cycle=2000){	//	Main experiment of ABM
	output {	//	Monitor updated values for each iteration
		monitor "Current Hour" value: my_date.hour;
		monitor "Date" value: my_date;	
		monitor "Day Counter" value: nb_day;
		monitor "Total Population" value: population;
		monitor "Initial Number of Susceptible" value: nb_susceptible_init;
		monitor "Initial Number of Infected" value: nb_infected_init;
		monitor "# of NEWLY INFECTED Individuals" value: num_newly_infect;
		monitor "# of INFECTED Individuals" value: nb_infected_people;
		monitor "# of SUSCEPTIBLE Individuals" value: nb_susceptible_people;
		monitor "# of RECOVERED Individuals" value: nb_recovered_people;
		monitor "# of HEALTHY Individuals" value: nb_susceptible_people + nb_recovered_people;
		
		display main_display {
			grid grid_cell lines: #black;
			species people aspect:circle;
		}
	}
}