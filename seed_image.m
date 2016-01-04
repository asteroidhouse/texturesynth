function [output_image, filled_map] = seed_image(input_image, seed_size, output_rows, output_cols)
% Creates an image of size (output_rows x output_cols), which has in the
% center a random (seed_size x seed_size) patch taken from the original
% input image.
%
% Inputs:
%   input_image: the original image used as the basis for sampling pixels
%   seed_size: the side length of the seed that will be copied from the
%              input_image and placed in the centre of the output_image
%   output_rows: the desired number of rows for the output image
%   output_cols: the desired number of columns for the output image
%
% Outputs:
%   output_image: an image of size (output_rows x output_cols) that is
%                 black, except for a seed in the centre
%   filled_map: a binary matrix that contains 0s, except in the centre,
%               where it has 1s corresponding to the seed pixels
% 
% The original_image is expected to have entries of type double
% The seed_size must be an odd integer that is less than or equal to 
% the minimum of the original_image width or height.

% Gets the dimensions of the input image
[input_rows input_cols channels] = size(input_image);

% Computes a margin for the right side and bottom of the image, to ensure
% that the random number selected for the 
margin = seed_size - 1;

rand_row = randi([1, input_rows - margin]);
rand_col = randi([1, input_cols - margin]);
seed_patch = input_image(rand_row:rand_row+margin, rand_col:rand_col+margin, :);

% Puts the seed patch in the centre of the output image.
output_image = zeros(output_rows, output_cols, channels);
center_row = floor(output_rows / 2);
center_col = floor(output_cols / 2);
half_seed_size = floor(seed_size / 2);
output_image(center_row-half_seed_size:center_row+half_seed_size, center_col - half_seed_size:center_col+half_seed_size, :) = seed_patch;

% Makes the seed patch positions equal to 1 in the filled map.
filled_map = false(output_rows, output_cols);
filled_map(center_row-half_seed_size:center_row+half_seed_size, center_col - half_seed_size:center_col+half_seed_size, :) = 1;