classdef imageCube< handle
    %IMAGECUBE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    properties (SetAccess = private)
        data
        cali
        sizes
        im_ave
        spec_ave
    end
    
    methods
        function obj = imageCube(varargin)
            %IMAGECUBE Construct an instance of this class
            %   Detailed explanation goes here
            obj.data  = im3D;
            obj.sizes = size(obj.data);
            
            if nargin == 1
                im3D = argin{1};
                dx = [1 1 1];
                offset = [0,0,0];
                unit = {'px','px','px'};
            elseif nargin == 4
                im3D = argin{1};
                dx = argin{2};
                offset = argin{3};
                unit = argin{4};
            else
                error('Invalid Input Error')
                
            end
            
            for ind = 1:3
                obj.cali(ind).dx     = dx(ind);
                obj.cali(ind).offset = offset(ind);
                obj.cali(ind).axes   = (0:(obj.sizes(ind)-1))*dx(ind) + offset(ind);
                obj.cali(ind).unit   = unit{ind};
            end

            
            
        end
        
        function resize(self,scales)
            
            for ind = 1:3

                ns(ind) = floor(self.sizes(ind)*scales(ind));
                self.cali(ind).dx = self.cali(ind).dx/scales(ind);

                self.cali(ind).axes = imresize( self.cali(ind).axes, [1, ns(ind)] );

                self.cali(ind).offset =  self.cali(ind).axes(1);
            end
            
            self.data = imresize3(self.data,ns);
            self.sizes = size(self.data);
        end
        

        
        function show3D(obj)
            obj.im_ave = mean(obj.data,3);
            obj.spec_ave = mean(obj.data, [1,2]);
            
            xbounds = [min(obj.cali(2).axes), max(obj.cali(2).axes)];
            ybounds = [min(obj.cali(1).axes), max(obj.cali(1).axes)];
            ebounds = [min(obj.cali(3).axes), max(obj.cali(3).axes)];
            
            
            figure;
            subplot(2,2,1)
            imh(1) = imagesc(obj.cali(2).axes,obj.cali(1).axes,obj.im_ave);
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

