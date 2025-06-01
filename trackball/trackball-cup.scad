$original_key_pitch=19.05;
$key_pitch=$original_key_pitch-0.5;
$torelance=0.1;
$cup_edge_length=($key_pitch - $torelance)*2;
$ball_torelance=0.30;
$ball_diameter=34; 
$ball_radius=$ball_diameter/2;
$subtract_ball_diameter=$ball_diameter+$ball_torelance*2;
$subtract_ball_radius=$subtract_ball_diameter/2;
$hull_ball_diameter=$cup_edge_length;
$hull_ball_radius=$hull_ball_diameter/2;
$support_diameter=2;
$support_radius=$support_diameter/2;
$holder_cylinder_diameter=3;
$holder_cylinder_radius=$holder_cylinder_diameter/2;
$holder_edge_length=$support_diameter+2;
$holder_height=$support_diameter*1.5;
$holder_cylinder_length=$holder_edge_length*2;
$lens_thickness=5;
$support_angle=45;
$fn = 128;

module subtract_ball(){
    translate([0,0,$subtract_ball_radius])sphere($subtract_ball_radius);
}

module hull_ball(){
    translate([0,0,$hull_ball_radius])sphere($hull_ball_radius);
}

module ball(){
    translate([0,0,$subtract_ball_radius])sphere($ball_radius);
}

module cup_base(lift_ratio){
    
    base_height=$subtract_ball_radius*0.1;
    difference(){
        hull(){
            translate([0,0,base_height/2]) cube([$cup_edge_length, $cup_edge_length, base_height], true);
            hull_ball();
        }
        translate([0,0,$subtract_ball_radius+$subtract_ball_diameter*lift_ratio]) cube([$cup_edge_length, $cup_edge_length, $subtract_ball_diameter], true);
        subtract_ball();
    }
}

module mirror_cover(){
    cover_height=$lens_thickness+1;
    translate([0,0,-cover_height/2]) cube([$cup_edge_length, $cup_edge_length, cover_height], true);
}

module cup_with_claw(){
    union(){
        intersection(){
            cup_base(0.7);
            scale([1,1,1.25 ]) rotate([90,0,0]) cylinder($key_pitch*2, r=$key_pitch, center=true);
        }
    }
    mirror_cover();
}

module subtract_support() {
    sphere($support_radius);
}

module support_holder(){
    scale_ratio=0.94;
    scale([scale_ratio, scale_ratio, scale_ratio]) {
        translate([0,0,-$holder_height-$support_diameter+0.31]) difference(){
            union(){
                difference(){
                    hull(){
                        translate([0,0,$holder_height/2]) cube([$holder_edge_length, $holder_edge_length, $holder_height], center=true);
                        translate([0,0,$holder_height]) sphere($holder_edge_length/2);
                    }
                    translate([0,0,$holder_height+$holder_edge_length/2-$support_radius/2]) subtract_support();
                    
                }
                translate([0,0,$holder_height/2]) rotate([90,0,0])cylinder($holder_cylinder_length, $holder_cylinder_radius, $holder_cylinder_radius, true);
            }
            cylinder($holder_height+$support_diameter, 0.6, 0.6, false);
        }
    }
}

module subtract_support_holder(){
    translate([0,0,-$holder_height-$support_diameter+0.31])
    union(){
        union(){
            difference(){
                hull(){
                    translate([0,0,$holder_height/2]) cube([$holder_edge_length, $holder_edge_length, $holder_height], center=true);
                    translate([0,0,$holder_height]) sphere($holder_edge_length/2);
                }
                translate([0,0,$holder_height+$holder_edge_length/2-$support_radius/2]) subtract_support();
                
            }
            translate([0,0,$holder_height/2]) rotate([90,0,0])cylinder($holder_cylinder_length, $holder_cylinder_radius, $holder_cylinder_radius, true);
        }
        translate([0,0,3*$holder_height/4+$holder_edge_length/4+$holder_cylinder_diameter*0.1]) rotate([90,0,0])cube([$holder_edge_length, $holder_height/2+$holder_edge_length/2, $holder_cylinder_length], true);
    }
}

module subtract_support_holders(scale_ratio){
    translate_x = $subtract_ball_radius*cos($support_angle-90);
    translate_y = $subtract_ball_radius*(1+sin($support_angle-90));
    union(){
        translate([translate_x,0,translate_y]) rotate([0,-$support_angle,0]) scale([scale_ratio,scale_ratio, scale_ratio]) subtract_support_holder();
        rotate([0,0,120]) translate([translate_x,0,translate_y]) rotate([0,-$support_angle,0]) scale([scale_ratio,scale_ratio, scale_ratio]) subtract_support_holder();
        rotate([0,0,240]) translate([translate_x,0,translate_y]) rotate([0,-$support_angle,0]) scale([scale_ratio,scale_ratio, scale_ratio]) subtract_support_holder();
    }
}

module support_holders(){
    translate_x = $subtract_ball_radius*cos($support_angle-90);
    translate_y = $subtract_ball_radius*(1+sin($support_angle-90));
    union(){
        translate([translate_x,0,translate_y]) rotate([0,-$support_angle,0]) support_holder();
        rotate([0,0,120]) translate([translate_x,0,translate_y]) rotate([0,-$support_angle,0]) support_holder();
        rotate([0,0,240]) translate([translate_x,0,translate_y]) rotate([0,-$support_angle,0]) support_holder();
    }
}

module subtract_lens() {
    translate([0,0,$lens_thickness/2]) union(){
        hull(){
            translate([7.25/2,-4.9/2,0])cylinder($lens_thickness, 7.05, 7.05, true);
            translate([7.25/2,4.9/2,0])cylinder($lens_thickness, 7.05, 7.05, true);
            translate([-7.25/2,-4.9/2,0])cylinder($lens_thickness, 7.05, 7.05, true);
            translate([-7.25/2,4.9/2,0])cylinder($lens_thickness, 7.05, 7.05, true);
        }
        translate([0.25,0,0])cube([21.35, 3, $lens_thickness], true);
    }
}

module subtract_lens_for_laser() {
    translate([10.97-21.35/2,0,0]) union(){
        translate([-2,0,0]) cube([4,4,$lens_thickness+30], true);
        cylinder($lens_thickness+30, 2, 2, true);
    }
}

module insert_holes(){
    translate([15.5,15.5,0]) cylinder(4,1.6,1.6, center=true);
    translate([15.5,-15.5,0]) cylinder(4,1.6,1.6, center=true);
    translate([-15.5,15.5,0]) cylinder(4,1.6,1.6, center=true);
    translate([-15.5,-15.5,0]) cylinder(4,1.6,1.6, center=true);
}

module cup(){
    centering_for_optical_center=21.35/2-10.97;
    translate([centering_for_optical_center,0,$lens_thickness+1]) difference(){
        cup_with_claw();
        subtract_support_holders(1.02);
        translate([0,0,-1-$lens_thickness]) subtract_lens();
        translate([0,0,-1-$lens_thickness]) subtract_lens_for_laser();
        translate([0,0,1-$lens_thickness]) insert_holes();
    }
}

module sensor_hole(){
    sensor_hole_width=10.7;
    sensor_hole_length=17.26;
    centering_for_optical_center=sensor_hole_length/2-8.44;
    sensor_hole_x_offset=centering_for_optical_center;
    translate([sensor_hole_x_offset,0,0]) cube([sensor_hole_length,sensor_hole_width,0.01], center=true);
}

cup();
//support_holders();
//support_holder();

// for debug
//projection(cut=false) sensor_hole();
//projection(cut=false) translate([0,0,+$lens_thickness]) difference(){cup();cube([30,30,100],center=true);};

