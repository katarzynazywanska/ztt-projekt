%Nadajnik, 

% 1. wariant a 
n = 1;
m = 10;
source_of_users_data = randi([0 1],n,m) 

V = [1 0 1 1]; 
poly(V);
input = [source_of_users_data 0 0 0]
output = deconv(input,V)