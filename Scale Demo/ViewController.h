//
//  ViewController.h
//  
//
//  Created by Guillermo Cubero on 11/28/17.
//  Copyright © 2017 Guillermo Cubero. All rights reserved.
//
//  Edited and Adapted by Andres Agauiza 1/1/18
//  Copyright © 2018 Andres Aguaiza. All rights reserved.


#import <UIKit/UIKit.h>

#import <StarIO_Extension/StarIoExtManager.h>

#import <StarMgsIO/StarMgsIO.h>

@interface ViewController : UIViewController <StarIoExtManagerDelegate, STARScaleManagerDelegate, STARScaleDelegate>

@property(nonatomic) STARScale *scale;

@property (weak, nonatomic) IBOutlet UIButton *ogSelected;
@property (weak, nonatomic) IBOutlet UIButton *printButton;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@end

