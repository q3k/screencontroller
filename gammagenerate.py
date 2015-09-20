import math

print 'module gamma(input [7:0] in, output reg [11:0] out);'
print 'always @(in) begin'
print 'case(in)'

gamma = 4

for i in range(256):
    f = float(i)/255.0
    o = int(math.pow(f, gamma) * (4095) + 0.5)
    print "\t8'h{:02x}: out = 12'h{:03x};".format(i, o)

print 'endcase'
print 'end'
print 'endmodule'
