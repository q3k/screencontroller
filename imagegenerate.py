from PIL import Image
im = Image.open('image.png')

width, height = im.size

print 'module image(input [4:0] x, input [4:0] y, output reg [7:0] r, output reg [7:0] g, output reg [7:0] b);'
print 'wire [9:0] ix = x << 5 | y;'
print 'always @(ix) begin'
print 'case(ix)'

for y in range(width):
    for x in range(height):
        ix = x << 5 | y
        r, g, b = im.getpixel((x, y))
        print "\t10'h{:03x}: begin r = 8'h{:02x}; g = 8'h{:02x}; b = 8'h{:02x}; end".format(ix, r, g, b)

print 'endcase'
print 'end'
print 'endmodule'

