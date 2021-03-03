im_si = readBigTiff('data/20210228 SI HAADF 135 kx 0023_SI.tiff');
im_adf = readBigTiff('data/20210228 SI HAADF 135 kx 0023_HAADF.tiff');

%%
dx = [0.37, 0.37, 0.005];
unit = {'nm','nm','px'};
offset = [0, 0, -0.25];

ic = imageCube( im_si, dx,offset,unit , im_adf);
ic.resize([1,1, 1/64])

%%
ic.setElements('C, Pt, Pb, Mn, Nb, Ti, O, Mo, Cu, Fe, Ga');