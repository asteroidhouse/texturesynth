input_image = im2double(imread('input/161.png'));

output_image = synthesize_texture(input_image, 256, 256, 9);

imwrite(output_image, 'result.png');