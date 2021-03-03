im_si = readBigTiff('data/20210228 SI HAADF 135 kx 0023_SI.tiff');
im_adf = readBigTiff('data/20210228 SI HAADF 135 kx 0023_HAADF.tiff');

%%
dx = [0.37, 0.37, 0.005];
unit = {'nm','nm','px'};
offset = [0, 0, -0.25];

ic = imageCube( im_si, dx,offset,unit , im_adf);
ic.resize([1,1, 1/4])

%%
ic.setElements('C, Pt, Pb, Mn, Nb, Ti, O, Mo, Cu, Fe, Ga, Cr, Ni, Zn');

ic.elements(1).selected = {'Ka1'};
ic.elements(2).selected = {'Ka1','Ka2','Kb1','La1','La2','Lb1','Lb2','Lg1','Ma1'};
ic.elements(3).selected = {'Ka1','Ka2','Kb1','La1','La2','Lb1','Lb2','Lg1','Ma1'};
ic.elements(4).selected = {'Ka1','Ka2','Kb1','La1','La2','Lb1'};
ic.elements(5).selected = {'Ka1','Ka2','Kb1','La1','La2','Lb1','Lb2','Lg1'};
ic.elements(6).selected = {'Ka1','Ka2','Kb1','La1','La2','Lb1'};
ic.elements(7).selected = {'Ka1'};
ic.elements(8).selected = {'Ka1','Ka2','Kb1','La1','La2','Lb1','Lb2','Lg1'};
ic.elements(9).selected = {'Ka1','Ka2','Kb1','La1','La2','Lb1'};
ic.elements(10).selected = {'Ka1','Ka2','Kb1','La1','La2','Lb1'};
ic.elements(11).selected = {'Ka1','Ka2','Kb1','La1','La2','Lb1'};
ic.elements(12).selected = {'Ka1','Ka2','Kb1','La1','La2','Lb1'};
ic.elements(13).selected = {'Ka1','Ka2','Kb1','La1','La2','Lb1'};
ic.elements(13).selected = {'Ka1','Ka2','Kb1','La1','La2','Lb1'};


%%
ic.E0 = 200;%keV
e_ax = ic.cali(3).axes;
tic
[edge_labels,x_guess] = ic.guessSpectrum;
toc

figure
hold on
plot(e_ax, ic.spec_ave);
plot(e_ax, ic.lorentz(x_guess,e_ax));
plot(e_ax, ic.bremss(x_guess(end,:),e_ax));

%%

x= [ 1, -1.9, 1/30];
xdata = e_ax;
figure
plot(e_ax,ic.bremss(x,xdata))