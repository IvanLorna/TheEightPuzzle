fprintf("CS170 Project 1");

%define the 3x3 matrix that is the 8 puzzle
%it is defined as the win condition
%the 0 is the blank space
solution = [
    1,2,3,;
    4,0,5,;
    6,7,8,]

%concatenated to the right of each matrix is the additional information
%[row of blank; 
% col of blank; 
% weight of path]
%this is a design choice targeted at removing the need to find the 0 space

%i will not create the code that randomly generates a combination of the 8
%puzzle, because it may not be in the parity needed to reach the solution,
%starting states can be input manually.
%i make the assumption a solution exists for the input initial state
problem = [
    4,1,3,3;
    2,7,5,1;
    0,6,8,0]


%if the depth of the problem is known, 
% we can use it for depth limitedearchs
%depth = 4

%this is the enumerator that will define the queueing function used by the
%algorithm
% 0-- Uniform Cost search
% 1-- A* with Misplaced Tile Heuristic
% 2-- A* with Manhattan Distance Hueristic
QUEUEING_FUNCTION = 2

%nodes is a 3D array representing the queue of matrix states 
%   nodes(:,:,1) = problem
%when appending a new node:
%   nodes(:,:,size(nodes,3)+1) = solution
%to sort this queue by path weight:
%   [~,SortOrder] = sort(node(3,4,:),3)
%   node(:,:,SortOrder)
%credit: https://www.mathworks.com/matlabcentral/answers/21201-sorting-3d-matrix-by-value-of-a-cell#answer_27937

%if you know how deep the answer is, make it a parameter as to avoid longer
%runtime than neccessary, useful for testing
max_depth = 0;

%execute the general search function derived from given psuedocode
answer = general_search(problem, solution, QUEUEING_FUNCTION,max_depth)

%test = [
%    8,0,2,1;
%    3,4,1,2;
%    6,7,5,0]
%MAKE_QUEUE(test,solution,QUEUEING_FUNCTION)
%%
function answer = general_search(problem,solution, QUEUEING_FUNCTION,max_depth) %answer is the return value
    nodes = MAKE_QUEUE(problem,solution, QUEUEING_FUNCTION);%nodes is the queue of states that the algorithm will analyze
    answer = ones([3,4])*-1; %-1 value represents failure to find a solution
    d = 0;
    while size(nodes,3) >= 1
        if nodes(1:3,1:3,1) == solution %solution check
            fprintf("solution found\n")
            answer = nodes(:,:,1);
            return;
        end
        if ((d >= max_depth) & (max_depth ~= 0))
            return;
        end
        nodes = UPDATE_QUEUE(nodes,solution,QUEUEING_FUNCTION); %update queue
        d = d+1;
    end
end

%queue updating helper function
%makes all posible "next moves" given a state, doesnt update the weight
%makes use of the row,col values in the 4th column of matrices to easily
%update the state, then readjusts the row,col values for next pass
function  q = MAKE_QUEUE(problem,solution,QUEUEING_FUNCTION)
    sz = 1; %number of added states, size of third dimension of q
    y = problem(1,4);
    x = problem(2,4);
    if y > 1 && x > 0
        q(:,:,sz) = problem;
        q(y,x,sz) = q(y-1,x,sz);
        q(y-1,x,sz) = 0;
        q(1,4,sz) = y-1;
        sz = sz + 1;
    end
    if y < 3 && x > 0
        q(:,:,sz) = problem;
        q(y,x,sz) = q(y+1,x,sz);
        q(y+1,x,sz) = 0;
        q(1,4,sz) = y+1;
        sz = sz + 1;
    end
    if x > 1 && y > 0
        q(:,:,sz) = problem;
        q(y,x,sz) = q(y,x-1,sz);
        q(y,x-1,sz) = 0;
        q(2,4,sz) = x-1;
        sz = sz + 1;
    end
    if x < 3 && y > 0
        q(:,:,sz) = problem;
        q(y,x,sz) = q(y,x+1,sz);
        q(y,x+1,sz) = 0;
        q(2,4,sz) = x+1;
    end
    
    %update weights of new nodes
    q = CALC_WEIGHTS(q,solution,QUEUEING_FUNCTION);
    return;
end

%weight recalculating helper function
%this is where queueing function comes into play
%calculates weight differently depending on input queueing function
function q = CALC_WEIGHTS(q,solution,QUEUEING_FUNCTION)
    switch QUEUEING_FUNCTION
        case 1
            q = MISPLACED_TILE(q,solution);
            
        case 2
            %fprinf("A* with manhattan distance heuristic")
            q = MANHATTAN_DISTANCE(q,solution);
        
        otherwise %Uniform Cost Search is used if 0 or an undefined value
            for i = 1:size(q,3)
                q(3,4,i) = q(3,4,i) + 1;
            end
    end
    return;
end

function q = MANHATTAN_DISTANCE(q,solution)
    for i = 1:size(q,3)
        q(3,4,i) = 0;
        for xs = 1:3
            for ys = 1:3
                for xp = 1:3
                    for yp = 1:3
                        if solution(ys,xs) == q(yp,xp,i)
                            q(3,4,i) = q(3,4,i) + abs(ys-yp) + abs(xs-xp);
                        end
                    end
                end
            end
        end
    end
end 

function q = MISPLACED_TILE(q,solution)
    for i = 1:size(q,3)
        sum = 0;
        for y = 1:3
            for x = 1:3
                if q(y,x,i) ~= solution(y,x)
                    sum = sum + 1;
                end
            end
        end
        q(3,4,i) = sum+1;
        
    end

end

function q = UPDATE_QUEUE(nodes, solution, QUEUEING_FUNCTION)
    %expand on top node
    q = MAKE_QUEUE(nodes(:,:,1),solution, QUEUEING_FUNCTION);
    %remove top node
    n_sz = size(nodes,3);
    %nodes(:,:,1) %uncomment to have popped nodes printed for output
    nodes = nodes(:,:,2:n_sz);
    n_sz = n_sz-1;
    
    %concatenate new nodes to queue
    q_sz = size(q,3);
    for i = 1:q_sz
        nodes(:,:,n_sz+i) = q(:,:,i);
    end
    %sort nodes by least weight to greatest
    [~,SortOrder] = sort(nodes(3,4,:),3);
    q = nodes(:,:,SortOrder);
    %while q(3,4,1) == 0
    %    q = q(:,:,2:size(q,3));
    %end
    %q is returned with new sorted nodes 
    return;
end