"""
A file with types, structs and functions for spatial simulations
"""

abstract type AbstractSpatialJump end

"""
placeholder for a jump
"""
struct NoSpatialJump <: AbstractSpatialJump end

struct SpatialReaction{S} <: AbstractSpatialJump
    site::S
    reaction_id::Int
end

struct SpatialDiffusion{S} <: AbstractSpatialJump
    source_site::S
    target_site::S
    species_id::Int
end

############ abstract spatial system struct ##################
"""
Contains all info about the topology of the system
"""
abstract type AbstractSpatialSystem end

"""
returns neighbors of site
"""
function neighbors end

"""
returns total number of sites
"""
function number_of_sites end

################### CartesianGrid <: AbstractSpatialSystem ########################

struct CartesianGrid <: AbstractSpatialSystem
    dimension::Int
    linear_size::Int #side length of the grid
end

dimension(grid::CartesianGrid) = grid.dimension

number_of_sites(grid) = grid.linear_size^dimension(grid)

is_site(grid,site_id) = site_id >= 1 && site_id <= number_of_sites(grid)

"""
return a generator that iterates over the neighbors of the given site in grid
"""
function neighbors(grid, site_id)
    (site_id + j*grid.linear_size^(i-1) for i in 1:dimension(grid), j in -1:2:1 if is_site(grid,site_id + j*grid.linear_size^(i-1)))
end

################### abstract spatial rates struct ###############

abstract type AbstractSpatialRates end

#return rate of site
function get_site_rate(spatial_rates_struct, site_id)
    site_reactions_rate(site_id)+site_diffusions_rate(site_id)
end

#return rate of reactions at site
function get_site_reactions_rate end

#return rate of diffusions at site
function get_site_diffusions_rate end

#returns an iterator over the pairs (rx_id,rx_rate) of a site
function get_site_reactions_iterator end

#returns an iterator over the pairs (species_id, diffusion_rate) of a site
function get_site_diffusions_iterator end

#sets the rate of reaction at site
function set_site_reaction_rate end

#sets the rate of diffusion at site
function set_site_diffusion_rate end

#################### SpatialRates <: AbstractSpatialRates ######################

# NOTE: for now assume diffusion rate only depends on the site and species (and not the neighbor of the site)
struct SpatialRates{R} <: AbstractSpatialRates
    reaction_rates::Vector{Vector{R}}
    diffusion_rates::Vector{Vector{R}}
    reaction_rates_sum::Vector{R}
    diffusion_rates_sum::Vector{R}
end

"""
standard constructor, assumes numeric values for rates
"""
function SpatialRates(reaction_rates::Vector{Vector{R}}, diffusion_rates::Vector{Vector{R}}) where {R}
    SpatialRates{R}(reaction_rates, diffusion_rates, sum(reaction_rates), sum(diffusion_rates))
end

"""
initializes SpatialRates with undefined rates
"""
function SpatialRates(num_jumps,num_species,num_sites)
    reaction_rates = [Vector{Real}(undef, num_jumps) for i in 1:num_sites]
    diffusion_rates = [Vector{Real}(undef, num_species) for i in 1:num_sites]
    reaction_rates_sum = zeros(num_sites)
    diffusion_rates_sum = zeros(num_sites)
    SpatialRates{Real}(reaction_rates,diffusion_rates,reaction_rates_sum,diffusion_rates_sum)
end

function SpatialRates(ma_jumps, num_species, spatial_system) where S
    num_sites = number_of_sites(spatial_system)
    num_jumps = get_num_majumps(ma_jumps)
    SpatialRates(num_jumps,num_species,num_sites)
end

#return rate of reactions at site
function get_site_reactions_rate(spatial_rates, site_id)
    spatial_rates.reaction_rates_sum
end

#return rate of diffusions at site
function get_site_diffusions_rate(spatial_rates, site_id)
    spatial_rates.diffusion_rates_sum
end

#returns an iterator over reaction rates of a site
function get_site_reactions_iterator(spatial_rates, site_id)
    spatial_rates.reaction_rates[site_id]
end

#returns an iterator over diffusion rates of a site
function get_site_diffusions_iterator(spatial_rates, site_id)
    spatial_rates.diffusion_rates[site_id]
end

#sets the rate of reaction at site
function set_site_reaction_rate!(spatial_rates, site_id, reaction_id, rate)
    old_rate = spatial_rates.reaction_rates[site_id][reaction_id]
    spatial_rates.reaction_rates[site_id][reaction_id] = rate
    spatial_rates.reaction_rates_sum = reaction_rates_sum - old_rate + rate
end

#sets the rate of diffusion at site
function set_site_diffusion_rate!(spatial_rates, site_id, species_id, rate)
    old_rate = spatial_rates.diffusion_rates[site_id][species_id]
    spatial_rates.diffusion_rates[site_id][site_id] = rate
    spatial_rates.diffusion_rates_sum = diffusion_rates_sum - old_rate + rate
end



# TODO do I need this?
# "return coordinates from node index and number of sites per box edge"
# node_to_coordinates(j,m) = ( (j-1)%m+1,(div(j-1,m))%m+1,(div(j-1,m^2)+1) )
#
# "return node index from coordinates and number of sites per box edge"
# coordinates_to_node(x,y,z,m) = x + (y-1)*m + (z-1)*m^2
#
# "return node index from coordinates and number of sites per box edge"
# coordinates_to_node(x,y,m) = x + (y-1)*m
#
# "return node index from coordinates and number of sites per box edge"
# coordinates_to_node(x,m) = x
#
# function connectivity_list_from_box(box_width :: Integer, dimension :: Integer)
#     @assert 1 <= dimension <= 3
#     vol_num = box_width^dimension
#     connectivity_matrix = Array{Array{Int64,1},1}(undef, 0)
#     for j in 1:vol_num
#         x,y,z = node_to_coordinates(j, box_width)
#         if dimension == 1
#             potential_neighbors = [(x-1,y,z), (x+1,y,z)]
#         elseif dimension == 2
#             potential_neighbors = [(x-1,y,z), (x+1,y,z), (x,y-1,z), (x,y+1,z)]
#         elseif dimension == 3
#             potential_neighbors = [(x-1,y,z), (x+1,y,z), (x,y-1,z), (x,y+1,z), (x,y,z-1), (x,y,z+1)]
#         end
#         real_neighbors = Int[]
#         for (x,y,z) in potential_neighbors
#
#             if 1<=x<=box_width && 1<=y<=box_width && 1<=z<=box_width
#                 push!(real_neighbors, coordinates_to_node(x,y,z,box_width))
#             end
#         end
#         push!(connectivity_matrix, real_neighbors)
#     end
#     return connectivity_matrix
# end
#
