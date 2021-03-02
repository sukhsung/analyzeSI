im_si = readBigTiff('data/20210228 SI HAADF 135 kx 0023_SI.tiff');

%%
dx = [0.37, 0.37, 0.005];
unit = {'nm','nm','px'};
offset = [0, 0, -0.25];

ic = imageCube( im_si, dx,unit,offset );
ic1 = imageCube( im_si, dx,unit,offset );
ic1.resize([1, 1, 0.125])