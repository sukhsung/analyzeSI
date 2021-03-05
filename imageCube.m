classdef imageCube< handle
    %IMAGECUBE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        elements
        E0
    end
    
    properties (SetAccess = private)
        data
        cali
        sizes
        im_ave
        spec_ave
        adf
    end
    
    methods
        function obj = imageCube(varargin)
            %IMAGECUBE Construct an instance of this class
            %   Detailed explanation goes here
            
            if nargin == 1
                im3D = varargin{1};
                dx = [1 1 1];
                offset = [0,0,0];
                unit = {'px','px','px'};
                adf = mean( im3D, 3);
            elseif nargin == 4
                im3D = varargin{1};
                dx = varargin{2};
                offset = varargin{3};
                unit = varargin{4};
                adf = mean( im3D, 3);
            elseif nargin == 5
                im3D = varargin{1};
                dx = varargin{2};
                offset = varargin{3};
                unit = varargin{4};
                adf = varargin{5};
            else
                error('Invalid Input Error')
                
            end
            
            addpath('./elements')
            
            obj.data  = double(im3D);
            obj.adf   = adf;
            obj.sizes = size(obj.data);
            
            for ind = 1:3
                obj.cali(ind).dx     = dx(ind);
                obj.cali(ind).offset = offset(ind);
                obj.cali(ind).axes   = ((0:(obj.sizes(ind)-1))*dx(ind) + offset(ind))';
                obj.cali(ind).unit   = unit{ind};
            end
            
            obj.spec_ave = squeeze( mean( obj.data, [1,2] ) );
            obj.im_ave   = mean( obj.data, 3) ;
            
        end
        
        function setElements(obj,symbols)
            obj.elements = parseElements( symbols, './elements/elements.csv' );
        end
        
        function [edge_labels,x0] = guessSpectrum(obj)
            gm = 0.015;
            
            edge = 0;
            eind = round((edge - obj.cali(3).offset)/obj.cali(3).dx + 1);
            if eind >=1 && eind<=obj.sizes(3)
                edge_labels = {'Zero-Loss'};
                A = obj.spec_ave(eind);
                x0 = [A, gm ,edge];
            else
                edge_labels = {};
                x0 = [];
            end
            
            numElements = length(obj.elements);
            
            
            for indElement = 1:numElements
                e = obj.elements(indElement);
                numSelected = length(e.selected);
                for indEdge = 1:numSelected
                    if isfield(e.EDS,e.selected{indEdge})
                        curEdge = e.EDS.(e.selected{indEdge});
                        if ~isnan(curEdge)
                            edge = curEdge/1000;
                            eind = round((edge - obj.cali(3).offset)/obj.cali(3).dx + 1);
                            if eind >=1 && eind<=obj.sizes(3)
                                A = obj.spec_ave(eind);
                                x0 = [x0;A, gm ,edge];
                                edge_labels = [edge_labels;[e.Symbol,'-',e.selected{indEdge}]];
                            end
                        else
                            error( [e.Symbol,'-',e.selected{indEdge}, 'is NaN'])
                        end
                    else
                        error( [e.selected{indEdge}, 'does not exist'])
                    end
                end
            end
            
            
            
            lb = x0; ub = x0;
            
            lb(:,1) = 0; ub(:,1) = inf;
            lb(:,2) = 0; ub(:,2) = 5*ub(:,2);
            lb(:,3) = lb(:,3) - 0.05; ub(:,3) = ub(:,3) +0.05;
            
            x0 = [x0; x0(1,1), -0.5, 0.5];
            lb = [lb; 0, -1      , 0];
            ub = [ub; inf, 0, 1];
            
            x0 = lsqcurvefit( @(x0,xdata) obj.lorentz(x0, xdata), x0, obj.cali(3).axes, obj.spec_ave, lb, ub );
                    
            
            
        end

        
        function resize(obj,scales)
            
            for ind = 1:3

                ns(ind) = floor(obj.sizes(ind)*scales(ind));
                obj.cali(ind).dx = obj.cali(ind).dx/scales(ind);

                obj.cali(ind).axes = imresize( obj.cali(ind).axes, [ns(ind),1] );

                obj.cali(ind).offset =  obj.cali(ind).axes(1);
            end
            
            obj.data = imresize3(obj.data,ns);
            obj.adf  = imresize(obj.adf, ns(1:2));
            obj.sizes = size(obj.data);
            
            obj.spec_ave = squeeze( mean( obj.data, [1,2] ) );
            obj.im_ave   = mean( obj.data, 3) ;
        end
        

        
        function show3D(obj)
            
            xbounds = [min(obj.cali(2).axes), max(obj.cali(2).axes)];
            ybounds = [min(obj.cali(1).axes), max(obj.cali(1).axes)];
            ebounds = [min(obj.cali(3).axes), max(obj.cali(3).axes)];
            
            
            figure;
            subplot(2,2,1)
            imh(1) = imagesc(obj.cali(2).axes,obj.cali(1).axes,obj.adf);
            xlabel(obj.cali(2).unit)
            ylabel(obj.cali(1).unit)
            axis equal image
            r(1) = drawrectangle('DrawingArea', 'auto',...
                'Position',[xbounds(1),ybounds(1),xbounds(2)-xbounds(1),ybounds(2)-ybounds(1)]);
            subplot(2,2,3)
            imh(2) = imagesc(obj.cali(2).axes,obj.cali(1).axes,obj.im_ave);
            xlabel(obj.cali(2).unit)
            ylabel(obj.cali(1).unit)
            axis equal image
            subplot(2,2,[2,4])
            imh(3) = plot(obj.cali(3).axes, squeeze( obj.spec_ave ));
            xlim([obj.cali(3).axes(1), obj.cali(3).axes(end)])
            ylim([0, max(obj.spec_ave)*1.1])
                
            r(2)   = drawrectangle('DrawingArea','auto',...
                'Position',[ebounds(1), 0,ebounds(2)-ebounds(1), 1.1*max(obj.spec_ave(:))]);
            
            
            addlistener(r(1),'MovingROI',@(src,evnt) obj.updateSpectrum(r, imh));
            addlistener(r(2),'MovingROI',@(src,evnt) obj.updateMap(r, imh));
            
           
        end
        
        function updateMap(obj,r, imh)
            obj.im_ave = mean(obj.data,3);
            e_bounds = [r(2).Position(1), r(2).Position(1)+r(2).Position(3)];
            einds = round((e_bounds - obj.cali(3).offset)/obj.cali(3).dx + 1);
            einds( einds<1) = 1;
            einds( einds>obj.sizes(3) ) = obj.sizes(3);
            
            imh(2).CData = mean( obj.data(:,:,einds(1):einds(2)),3);


        end    
        
        function updateSpectrum(obj,r, imh)
            x_bounds = [r(1).Position(1), r(1).Position(1)+r(1).Position(3)];
            y_bounds = [r(1).Position(2), r(1).Position(2)+r(1).Position(4)];

            xinds = round((x_bounds - obj.cali(2).offset)/obj.cali(2).dx + 1);
            yinds = round((y_bounds - obj.cali(1).offset)/obj.cali(1).dx + 1);

            xinds( xinds<1) = 1;
            yinds( yinds<1) = 1;
            xinds( xinds>obj.sizes(2) ) = obj.sizes(2);
            yinds( yinds>obj.sizes(1) ) = obj.sizes(1);

            imh(3).YData = mean( obj.data(yinds(1):yinds(2),xinds(1):xinds(2),:),[1,2]);

        end
        
        function ydata = lorentz(obj,x,xdata)
    
            numLorents = size(x,1)-1;
            ydata = zeros(size(xdata));

            for ind = 1:numLorents
                ydata = ydata+...
                    (x(ind,1)*(x(ind,2)^2))./(((x(ind,2)^2) + (xdata-x(ind,3)).^2 ));
            end
            
            
            
            
            ydata = ydata+ obj.bremss(x(end,:),xdata);

        end

        function ydata = bremss(obj,x,xdata)
         %   xdata( xdata<0 ) =0;
            
            kramer = (obj.E0-xdata).*(xdata.^-1);
            de     = (1-exp(-xdata));
            ydata = x(1)*kramer.*de;
            figure
            hold on
            plot(xdata,kramer*0.01)
            plot(xdata,de)
            plot(xdata,de.*kramer*0.01)
            ylim([0,5])
            %ydata( isnan(ydata) ) = 0;
        end

        
        
        function show2D(obj)
            obj.im_ave = mean(obj.data,3);
            figure;
            imagesc(obj.cali(2).axes,obj.cali(1).axes,obj.im_ave);
            xlabel(obj.cali(2).unit)
            ylabel(obj.cali(1).unit)
            xlim([obj.cali(2).axes(1), obj.cali(2).axes(end)])
            ylim([obj.cali(1).axes(1), obj.cali(1).axes(end)])
            axis equal
        end
    end
end

