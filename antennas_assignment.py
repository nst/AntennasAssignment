#!/usr/bin/python

import sys
import random
from random import randint
import json
import math
import png # $ sudo pip install pypng, https://github.com/drj11/pypng

#random.seed(0)

def read_img_grid(image_path):
    f = open(image_path)
    img = png.Reader(file=f).read()
    return [ [(255.0-p)/255.0 for p in row[::4]] for row in img[2] ]
    
def compute_random_antenna_locations(antennas, pop_grid):

    width, height = len(pop_grid[0]), len(pop_grid)
    
    ll = []
    for t, d in antennas.iteritems():
        for i in range(d['qty']):
            ll.append([t, randint(0, width-1), randint(0, height-1)])
    
    return ll

def build_cov_cost_grid(antennas, cost_grid, antennas_locations):
    
    width, height = len(cost_grid[0]), len(cost_grid)
    
    grid = []
    for h in range(height):
        grid.append([None] * width)
    
    for (t, x, y) in antennas_locations:
        a = antennas[t]
        power = a['power']
        cost = cost_grid[y][x]
        
        for x_ in range(max(0, x-power), min(x+power+1, width)):
            for y_ in range(max(0, y-power), min(y+power+1, height)):
                distance = math.sqrt((math.fabs(x_ - x)**2 + math.fabs(y_ - y)**2))
                intensity = (power - distance) / power
                if intensity > 0.0:
                    grid[y_][x_] = cost
                    
    return grid

def evalute_covered_people(pop_grid, cov_grid):
    
    width, height = len(pop_grid[0]), len(pop_grid)

    assert(len(cov_grid[0]) == width)
    assert(len(cov_grid) == height)

    return sum([sum([ pop_grid[y][x] if cov_grid[y][x] is not None else 0.0 for x in range(width) ]) for y in range(height)])

def evaluate_costs(antennas, cost_grid, antennas_locations):
    width, height = len(cost_grid[0]), len(cost_grid)
    return sum([cost_grid[y][x] for (t, x, y) in antennas_locations])

def evaluate_solution(antennas, pop_grid, cost_grid, antennas_locations):

    cov_cost_grid = build_cov_cost_grid(antennas, cost_grid, antennas_locations)
    people_covered = evalute_covered_people(pop_grid, cov_cost_grid)
    costs = evaluate_costs(antennas, cost_grid, antennas_locations)
    
    return (people_covered, costs, cov_cost_grid)

def write_solution_image(antennas, pop_grid, cov_cost_grid, solution, path):
    
    full_grid = []
    for y in range(height):
        l = []
        for x in range(width):
            p = pop_grid[y][x]
            cost = cov_cost_grid[y][x]
            if cost is None:
                v = (1.0-p) * 255.0
                l += (v, v, v)
            else:
                (r, g, b) = ( cost * 255.0, p * 255.0, 0 )
                l += (r, g, b)
        full_grid.append(l)
    
    print "writing", path
    f = open(path, 'wb')
    w = png.Writer(width, height)
    w.write(f, full_grid)
    f.close()

def read_from_json(path):
    o = None
    with open(path, 'r') as f:
        o = json.load(f)
    return o

def write_to_json(o, path):
    print "writing", path
    s = json.dumps(o, indent=4, sort_keys=True)
    f = open(path, 'w')
    f.write(s)
    f.close()

def compute_best_solution(antennas, pop_grid, cost_grid, budget):
    return compute_random_antenna_locations(antennas, pop_grid)

if __name__ == "__main__":
    
    # read pop
    
    pop_grid = read_img_grid("pop.png")
    width, height = len(pop_grid[0]), len(pop_grid)
    print "grid: %dx%d" % (width, height)
    total_pop = sum([sum(l) for l in pop_grid])
    print "total_pop: %.02f" % total_pop

    #write_to_json(pop_grid, "pop_grid.json")

    # read costs

    cost_grid = read_img_grid("cost.png")
    total_possible_costs = sum([sum(l) for l in cost_grid])
    print "total_possible_costs: %.02f" % total_possible_costs

    #write_to_json(cost_grid, "cost_grid.json")
    
    assert(len(cost_grid) == len(pop_grid))
    assert(len(cost_grid[0]) == len(pop_grid[0]))

    # read antennas and budget

    antennas_and_budget = read_from_json('antennas_and_budget.json')

    antennas = antennas_and_budget['antennas']
    budget = antennas_and_budget['budget']
    
    print "budget:", budget

    # use given solution, on generate one
    
    solution = None
    
    if len(sys.argv) == 2:
        solution_path = sys.argv[1]
        solution = read_from_json(solution_path)
    else:
        solution = compute_best_solution(antennas, pop_grid, cost_grid, budget)
        write_to_json(solution, 'solution.json')                

    # evaluate solution
    
    (people_covered, costs, cov_cost_grid) = evaluate_solution(antennas, pop_grid, cost_grid, solution)
        
    print "people_covered: %d (%.02f%%), cost: %f" % (people_covered, (100.0 * people_covered / total_pop), costs)
    if costs > budget:
        print "-- warning, costs over budget: %d > %d" % (costs, budget)    
    
    write_solution_image(antennas, pop_grid, cov_cost_grid, solution, "out.png")
    