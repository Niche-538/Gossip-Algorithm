# **Distributed Operating Systems - Project 2**

## Gossip Algorithm

### **Group Members-**
* Anurag Patil
* Pratik Kamble

### Problem Definition
* Gossip type algorithms can be used both for group communication and for aggregate computation. 
* The goal of this project is to determine the convergence of such algorithms through a simulator based on actors written in Erlang. 
* Since actors are fully asynchronous, the particular type of Gossip implemented is the so-called Asynchronous Gossip.

#### Gossip Algorithm for information propagation 
The Gossip algorithm involves the following:
* Starting: A participant(actor) told/sent a rumor (fact) by the main process
* Step: Each actor selects a random neighbor and tells it the rumor.
* Termination: Each actor keeps track of rumors and how many times he has heard the rumor. It stops transmitting once it has heard the rumor 10 times (10 is arbitrary, you can select other values).

#### Push-Sum algorithm for sum computation
* State: Each actor Ai maintains two quantities: s and w. Initially, s  = xi = i (that is actor number i has value i, play with other distribution if you so desire) and w = 1
* Starting: Ask one of the actors to start from the main process.
* Receive: Messages sent and received are pairs of the form (s, w). Upon receiving, an actor should add the received pair to its own corresponding values. Upon receiving, each actor selects a random neighbor and sends it a message.
* Send: When sending a message to another actor, half of s and w is kept by the sending actor, and half is placed in the message.
* Sum Estimate: At any given moment of time, the sum estimate is s/w where s and w are the current values of an actor.
* Termination: If an actor's ratio s/w did not change more than 10−10 in 3 consecutive rounds the actor terminates. WARNING: the values s and w independently never converge, only the ratio does.

#### Topologies: 
The actual network topology plays a critical role in the dissemination speed of Gossip protocols. As part of this project, you have to experiment with various topologies. The topology determines who is considered a neighbor in the above algorithms.

* Full Network: Every actor is a neighbor of all other actors. That is, every actor can talk directly to any other actor.
* 2D Grid: Actors form a 2D grid. The actors can only talk to the grid neighbors
* Line: Actors are arranged in a line. Each actor has only 2 neighbors (one left and one right, unless you are the first or last actor).
* Imperfect 3D Grid: Grid arrangement but one random other neighbor is selected from the list of all actors (8+1 neighbors).

### Steps to run the code
* Clone this repository and install erlang.


### Conclusions and Results

1. What is working:
    1. To do
    2. To do
    3. To do

2. What is the largest network you managed to deal with for each type of topology and algorithm?
   1. To do
   2. To To
  
3. Report.pdf For each type of topology and algorithm, draw the dependency of convergence time as a function of the size of the network. You can overlap different topologies on the same graph, i.e. you can draw 4 curves, one for each topology, and produce only 2 graphs for the two algorithms. Write about any interesting findings of your experiments in the report as well and mention the team members.
You can produce Report.pdf in any way you like, for example using spreadsheet software. You might have to use logarithmic scales to have a meaningful plot.
4. Bonus : In the above assignment, there is no failure at all. For a 30% bonus, implement node and failure models (a node dies,  a connection dies temporarily or permanently). Write a Report-bonus.pdf to explain your findings (how you tested, what experiments you performed, what you observed) and submit project2-bonus.tgz/zip with your code. To get the bonus you must implement at least one failure model controlled by a parameter and draw plots that involve the parameter. At least one interesting observation has to be made based on these plots.