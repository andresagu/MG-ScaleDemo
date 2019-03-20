//
//  ViewController.m
//
//
//  Created by Guillermo Cubero on 11/28/17.
//  Copyright © 2017 Guillermo Cubero. All rights reserved.
//
//  Edited and Adapted by Andres Agauiza 1/1/19
//  Copyright © 2018 Andres Aguaiza. All rights reserved.


#import "ViewController.h"
#import "AppDelegate.h"
#import "Communication.h"
#import "GlobalQueueManager.h"

typedef NS_ENUM(NSInteger, CellParamIndex) {
    CellParamIndexBarcodeData = 0
};

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

/* BUTTON PRESS ACTIONS */
- (IBAction)pushRefreshButton:(id)sender;
- (IBAction)pressCannabisLabelButton:(id)sender;




/* STAR IO *//* UI ELEMENTS */
//The horrid Scale Weights here
@property (weak, nonatomic) IBOutlet UITextView *scaleWeight;
@property (weak, nonatomic) IBOutlet UITextView *scaleWeight2;
@property (weak, nonatomic) IBOutlet UITextView *scaleWeight3;
@property (weak, nonatomic) IBOutlet UITextView *scaleWeight4;
@property (weak, nonatomic) IBOutlet UITextView *scaleWeight5;
@property (weak, nonatomic) IBOutlet UITextView *scaleWeight6;
@property (weak, nonatomic) IBOutlet UITextView *scaleWeight7;
@property (weak, nonatomic) IBOutlet UITextView *scaleWeight8;


@property (nonatomic) StarIoExtManager *starIoExtManager;
@property SMPort *port;

/* STAR SCALE */
@property(nonatomic) NSMutableArray<STARScale *> *contents;
@property(nonatomic) STARScale *connectedScale;
@property (nonatomic) NSDictionary<NSNumber *, NSString *> *unitDict;

@property (nonatomic) NSString *currentWeight;
@property (nonatomic) NSString *price;

/* APP STATE */
- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;


@property(nonatomic) NSString *scaleW;

//arrays to save weight data for receipt builder
@property(nonatomic)NSMutableArray *weightData;
@property(nonatomic)NSMutableArray *itemName;

//Booleans to keep track of selected strains
@property(nonatomic) Boolean isOG;
@property(nonatomic) Boolean isBlue;
@property(nonatomic) Boolean isGreen;
@property(nonatomic) Boolean isPurple;
@property(nonatomic) Boolean isGirlScout;
@property(nonatomic) Boolean isSour;
@property(nonatomic) Boolean isCookies;
@property(nonatomic) Boolean isLights;



//Booleans to keep track of application states
@property(nonatomic) Boolean itemScanned;
@property(nonatomic) Boolean itemSelected;
@property(nonatomic) Boolean orderComplete;

//Pricing Tracker
@property(nonatomic) double pricePerGram;
@property(nonatomic) double finalPrice;
@property(nonatomic) NSString* priceToPrint;
@property(nonatomic) NSString* barcodeData;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initDictionaries];
    
    //set all the scale weights at invisible
    [_scaleWeight setAlpha:0];
    [_scaleWeight2 setAlpha:0];
    [_scaleWeight3 setAlpha:0];
    [_scaleWeight4 setAlpha:0];
    [_scaleWeight5 setAlpha:0];
    [_scaleWeight6 setAlpha:0];
    [_scaleWeight7 setAlpha:0];
    [_scaleWeight8 setAlpha:0];
    
    [_printButton setAlpha:0];
    
    
    // Instantiate our connection to the printer & barcode scanner
    _starIoExtManager = [[StarIoExtManager alloc] initWithType:StarIoExtManagerTypeWithBarcodeReader
                                                      portName:[AppDelegate getPortName]
                                                  portSettings:[AppDelegate getPortSettings]
                                               ioTimeoutMillis:10000];                                   // 10000mS!!!
    
    // Set drawer polarity
    _starIoExtManager.cashDrawerOpenActiveHigh = [AppDelegate getCashDrawerOpenActiveHigh];
    
    // Setup the printer delegate methods
    _starIoExtManager.delegate = self;
    
    // Setup the ScaleManager delegate methods
    STARScaleManager.sharedManager.delegate = self;
    
    // An arrray for storing discovered BLE scales
    _contents = [NSMutableArray new];
    
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    // Start scanning for scales
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(),^{
        [STARScaleManager.sharedManager scanForScales];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive)  name:UIApplicationDidBecomeActiveNotification  object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification  object:nil];
}

- (void)applicationDidBecomeActive {
    
    [_starIoExtManager disconnect];
    
    NSString *title = @"";
    NSString *message = @"";
    
    if ([_starIoExtManager connect] == NO) {
        
        title = @"Printer Connection Error";
        message = @"Failed to connect to mC-Print. Please ensure the lightning cable is connected and try again.";
    }
    else {
        title = @"Printer Detected"; message = @"mC-Print is now connected.";
    }
    if (_connectedScale != nil) {
        [STARScaleManager.sharedManager connectScale:_connectedScale];
    }
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   // Handle OK button press action here
                                   // Currently do nothing
                               }];
    
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)applicationWillResignActive {
    [_starIoExtManager disconnect];
    
    //disconnect the scale manager & delegate methods when the
    if (_connectedScale != nil) {
        [STARScaleManager.sharedManager disconnectScale:_connectedScale];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Triggered when you push the refresh button
- (IBAction)pushRefreshButton:(id)sender {
    
    
    [_starIoExtManager disconnect];
    [_printButton setAlpha:0];
    [_infoLabel setAlpha:1];
    
    NSString *title = @"";
    NSString *message = @"";
    
    if ([_starIoExtManager connect] == NO) {
        title = @"Printer Connection Error";
        message = @"Failed to connect to mC-Print. Please ensure the lightning cable is connected and try again.";
    }
    else {
        title = @"Printer Detected"; message = @"mC-Print is now connected.";
    }

    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle your yes please button action here
                                   // Do nothing
                               }];
    
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}




- (void)initDictionaries {
    _unitDict = @{@(STARUnitInvalid): @"Invalid",
                  @(STARUnitMG): @"mg",
                  @(STARUnitG): @"g",
                  @(STARUnitCT): @"ct",
                  @(STARUnitMOM): @"mom",
                  @(STARUnitOZ): @"oz",
                  @(STARUnitLB): @"pound",
                  @(STARUnitOZT): @"ozt",
                  @(STARUnitDWT): @"dwt",
                  @(STARUnitGN): @"GN",
                  @(STARUnitTLH): @"tlH",
                  @(STARUnitTLS): @"tlS",
                  @(STARUnitTLT): @"tlT",
                  @(STARUnitTO): @"to",
                  @(STARUnitMSG): @"MSG",
                  @(STARUnitBAT): @"BAt",
                  @(STARUnitPCS): @"PCS",
                  @(STARUnitPercent): @"%",
                  @(STARUnitCoefficient): @"#"
                  };
}

- (void)didPrinterImpossible:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterOnline:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterOffline:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterPaperReady:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterPaperNearEmpty:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    /* The following printers do not have a low paper sensor:
     * TSP100, TSP100III, mC-Print, mPOP, portables
     */
}

- (void)didPrinterPaperEmpty:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterCoverOpen:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didPrinterCoverClose:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didCashDrawerOpen:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didCashDrawerClose:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didBarcodeReaderImpossible:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didBarcodeReaderConnect:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didBarcodeReaderDisconnect:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didAccessoryConnectSuccess:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didAccessoryConnectFailure:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didAccessoryDisconnect:(StarIoExtManager *)manager {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)didStatusUpdate:(StarIoExtManager *)manager status:(NSString *)status {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (IBAction)pressPrintButton:(id)sender {
    
    [self createCanabisTicket];
    
    [_printButton setAlpha:0];

   
}


#pragma mark - STARScaleManagerDelegate

- (void)manager:(STARScaleManager *)manager didDiscoverScale:(STARScale *)scale error:(NSError *)error {
    [_contents addObject:scale];
    
    [STARScaleManager.sharedManager stopScan];
    [STARScaleManager.sharedManager connectScale:scale];
}

- (void)manager:(STARScaleManager *)manager didConnectScale:(STARScale *)scale error:(NSError *)error {
    NSLog(@"Scale %@ is now connected", scale.name);
    
    _connectedScale = scale.self;
    _connectedScale.delegate = self;
}

- (void)manager:(STARScaleManager *)manager didDisconnectScale:(STARScale *)scale error:(NSError *)error {
    NSLog(@"Scale %@ has been disconnected", scale.name);
}


//Theres some debugging thats gunna need to go down in here. This is where we get alot of null values when things aren't done in a certain order. Will just have to implement checks here. nothing tragic happens but it's not solid. -- I think the best idea would be to implement the price calculation in the strain selection action so that it updates accordingly...if it's null it'l throw an exception to weigh..fool proof

- (void)scale:(STARScale *)scale didReadScaleData:(STARScaleData *)scaleData error:(NSError *)error {
    
    _currentWeight = [NSString stringWithFormat:@"%.03lf [%@]", scaleData.weight, _unitDict[@(scaleData.unit)]];
    _price = [NSString stringWithFormat:@"$%.02lf", scaleData.weight * 10];
    _scaleW = [NSString stringWithFormat:@"%.02lf [%@]", scaleData.weight, _unitDict[@(scaleData.unit)]];
    
    //Set all the scale weights
    
    _scaleWeight.text = [NSString stringWithFormat:@"%.02lf %@", scaleData.weight,
                         _unitDict[@(scaleData.unit)]];
 
    _scaleWeight2.text = [NSString stringWithFormat:@"%.02lf %@", scaleData.weight,
                              _unitDict[@(scaleData.unit)]];
 
    _scaleWeight3.text = [NSString stringWithFormat:@"%.02lf %@", scaleData.weight,
                             _unitDict[@(scaleData.unit)]];

    _scaleWeight4.text = [NSString stringWithFormat:@"%.02lf %@", scaleData.weight,
                             _unitDict[@(scaleData.unit)]];
  
    _scaleWeight5.text = [NSString stringWithFormat:@"%.02lf %@", scaleData.weight,
                              _unitDict[@(scaleData.unit)]];
    
    _scaleWeight6.text = [NSString stringWithFormat:@"%.02lf %@", scaleData.weight,
                          _unitDict[@(scaleData.unit)]];
   
    _scaleWeight7.text = [NSString stringWithFormat:@"%.02lf %@", scaleData.weight,
                              _unitDict[@(scaleData.unit)]];
 
    _scaleWeight8.text = [NSString stringWithFormat:@"%.02lf %@", scaleData.weight,
                              _unitDict[@(scaleData.unit)]];
    
    _finalPrice  = scaleData.weight * _pricePerGram;
    
    _priceToPrint = [NSString stringWithFormat:@"$%.02lf", _finalPrice];

    [self sendDataToDisplay];
    
    
}

- (void)scale:(STARScale *)scale didUpdateSetting:(STARScaleSetting)setting error:(NSError *)error {
    if (error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil];
        [alert addAction:action];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}



-(void)createBarcodeData{
    
    if(_priceToPrint != nil){
    
    if (_isOG == TRUE) {
        _barcodeData = [@"{BOG!" stringByAppendingString:_priceToPrint];
    }
    else if (_isBlue==TRUE){
        _barcodeData = [@"{BBD!" stringByAppendingString:_priceToPrint];
        
    }
    else if (_isPurple==TRUE){
        _barcodeData= [@"{BPH!" stringByAppendingString:_priceToPrint];
    }
    else if (_isGirlScout==TRUE){
        _barcodeData= [@"{BPX!" stringByAppendingString:_priceToPrint];
    }
    else if (_isSour){
        _barcodeData= [@"{BSD!" stringByAppendingString:_priceToPrint];
    }
    else if (_isGreen){
        _barcodeData= [@"{BGC!" stringByAppendingString:_priceToPrint];
    }
    else if (_isLights){
            _barcodeData= [@"{BNL!" stringByAppendingString:_priceToPrint];
    }
    else if (_isCookies){
        _barcodeData= [@"{BCK!" stringByAppendingString:_priceToPrint];
    }
        
    else{
        NSLog(@"please weigh something");
    }
        
    }
    
}

-(void)createCanabisTicket {
    
    //again set all scale weights at invis
    [_scaleWeight setAlpha:0];
    [_scaleWeight2 setAlpha:0];
    [_scaleWeight3 setAlpha:0];
    [_scaleWeight4 setAlpha:0];
    [_scaleWeight5 setAlpha:0];
    [_scaleWeight6 setAlpha:0];
    [_scaleWeight7 setAlpha:0];
    [_scaleWeight8 setAlpha:0];
    
    //info label returns
    [_infoLabel setAlpha:1];
    
    NSLog(@"%@", _scaleW);
    
    [self createBarcodeData];
    
    
    //builder
    ISCBBuilder *Ticket = [StarIoExt createCommandBuilder:StarIoExtEmulationStarPRNT];
    NSStringEncoding encoding = NSASCIIStringEncoding;
    
    [Ticket beginDocument];
    
    [Ticket appendMultipleWidth:2];
    [Ticket appendMultipleHeight:2];
    [Ticket appendAlignment:SCBAlignmentPositionCenter];
    [Ticket appendData:[@"Please scan this ticekt at checkout" dataUsingEncoding:encoding]];
    [Ticket appendMultipleWidth:4];
    [Ticket appendMultipleHeight:4];
    [Ticket appendAlignment:SCBAlignmentPositionCenter];
    [Ticket appendLineFeed:2];
    [Ticket appendDataWithEmphasis:[_scaleW dataUsingEncoding:encoding]];
    [Ticket appendLineFeed];
    [Ticket appendMultipleHeight:1];
    [Ticket appendMultipleWidth:1];
    [Ticket appendAlignment:SCBAlignmentPositionCenter];
    [Ticket appendBarcodeData:[_barcodeData dataUsingEncoding:NSASCIIStringEncoding]
                            symbology:SCBBarcodeSymbologyCode128
                                width:SCBBarcodeWidthMode2
                               height:40
                                  hri:YES];
    
    [Ticket appendLineFeed];
    [Ticket appendCutPaper:SCBCutPaperActionPartialCutWithFeed];
    [Ticket endDocument];
    NSData *printJob = [Ticket.commands copy];
    
    [_starIoExtManager.lock lock];
    [Communication sendCommandsDoNotCheckCondition:printJob port:_starIoExtManager.port completionHandler:^(BOOL result, NSString *title, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result == NO) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                
                [alertView show];
            }
            [_starIoExtManager.lock unlock];
        });
    }];
    
    
}

//SELECTED STRAIN BUTTONS



- (IBAction)ogSelected:(id)sender {
    
    [_scaleWeight setAlpha:1];
    
    //enable printing
    [_printButton setAlpha:1];
    
    //hide all otehr weight views
    [_scaleWeight2 setAlpha:0];
    [_scaleWeight3 setAlpha:0];
    [_scaleWeight4 setAlpha:0];
    [_scaleWeight5 setAlpha:0];
    [_scaleWeight6 setAlpha:0];
    [_scaleWeight7 setAlpha:0];
    [_scaleWeight8 setAlpha:0];
    
    
    
    
    
    
    _isOG = TRUE;
    _pricePerGram = 7.59;
    
    //set rest to false
    _isBlue=FALSE;
    _isPurple=FALSE;
    _isGirlScout=FALSE;
    _isSour=FALSE;
    _isGreen=FALSE;
    _isCookies=FALSE;
    _isLights=FALSE;
    
}


- (IBAction)blueSelected:(id)sender {
    
    
    [_scaleWeight8 setAlpha:1];
    [_infoLabel setAlpha:0];
    
    //enable printing
    [_printButton setAlpha:1];
    
    //hide all otehr weight views
    [_scaleWeight2 setAlpha:0];
    [_scaleWeight3 setAlpha:0];
    [_scaleWeight4 setAlpha:0];
    [_scaleWeight5 setAlpha:0];
    [_scaleWeight6 setAlpha:0];
    [_scaleWeight7 setAlpha:0];
    [_scaleWeight setAlpha:0];
    
    
    _isBlue = TRUE;
    
    _pricePerGram = 9.39;
    
    _isOG=FALSE;
    _isPurple=FALSE;
    _isGirlScout=FALSE;
    _isSour=FALSE;
    _isGreen=FALSE;
    _isCookies=FALSE;
    _isLights=FALSE;

    
}

- (IBAction)purpleSelected:(id)sender {
    
    [_infoLabel setAlpha:0];
    [_scaleWeight4 setAlpha:1];
    
    //enable printing
    [_printButton setAlpha:1];
    
    
    
    //hide all other weight views
    [_scaleWeight2 setAlpha:0];
    [_scaleWeight3 setAlpha:0];
    [_scaleWeight5 setAlpha:0];
    [_scaleWeight6 setAlpha:0];
    [_scaleWeight7 setAlpha:0];
    [_scaleWeight8 setAlpha:0];
    [_scaleWeight setAlpha:0];
    
    
    
    _isPurple = TRUE;
    
    _pricePerGram = 8.10;
    
    _isBlue=FALSE;
    _isOG=FALSE;
    _isGirlScout=FALSE;
    _isSour=FALSE;
    _isGreen=FALSE;
    _isCookies=FALSE;
    _isLights=FALSE;

}

- (IBAction)cookiesSelected:(id)sender {
    
    [_scaleWeight6 setAlpha:1];
    [_infoLabel setAlpha:0];
    
    //enable printing
    [_printButton setAlpha:1];
    
    //hide all otehr weight views
    [_scaleWeight2 setAlpha:0];
    [_scaleWeight3 setAlpha:0];
    [_scaleWeight4 setAlpha:0];
    [_scaleWeight5 setAlpha:0];
    [_scaleWeight7 setAlpha:0];
    [_scaleWeight8 setAlpha:0];
    [_scaleWeight setAlpha:0];
    
    
    _isGirlScout = TRUE;
    
    _pricePerGram = 8.14;
    
    _isBlue=FALSE;
    _isPurple=FALSE;
    _isOG=FALSE;
    _isSour=FALSE;
    _isGreen=FALSE;
    _isCookies=FALSE;
    _isLights=FALSE;

    
}


- (IBAction)sourSelected:(id)sender {
    
    [_scaleWeight2 setAlpha:1];
    [_infoLabel setAlpha:0];
    
    //enable printing
    [_printButton setAlpha:1];
    
    //hide all otehr weight views
    [_scaleWeight3 setAlpha:0];
    [_scaleWeight4 setAlpha:0];
    [_scaleWeight5 setAlpha:0];
    [_scaleWeight6 setAlpha:0];
    [_scaleWeight7 setAlpha:0];
    [_scaleWeight8 setAlpha:0];
    [_scaleWeight setAlpha:0];
    
    
    _isSour = TRUE;
    
    _pricePerGram = 7.80;
    
    _isBlue=FALSE;
    _isPurple=FALSE;
    _isGirlScout=FALSE;
    _isOG=FALSE;
    _isGreen=FALSE;
    _isCookies=FALSE;
    _isLights=FALSE;

}

- (IBAction)greenSelected:(id)sender {
    
    
    [_scaleWeight7 setAlpha:1];
    [_infoLabel setAlpha:0];
    
    //enable printing
    [_printButton setAlpha:1];
    
    //hide all otehr weight views
    [_scaleWeight2 setAlpha:0];
    [_scaleWeight3 setAlpha:0];
    [_scaleWeight4 setAlpha:0];
    [_scaleWeight5 setAlpha:0];
    [_scaleWeight6 setAlpha:0];
    [_scaleWeight8 setAlpha:0];
    [_scaleWeight setAlpha:0];
    
    
    _isGreen = TRUE;
    
    _pricePerGram = 6.59;
    
    _isBlue=FALSE;
    _isPurple=FALSE;
    _isGirlScout=FALSE;
    _isSour=FALSE;
    _isOG=FALSE;
    _isCookies=FALSE;
    _isLights=FALSE;

    
    
}
- (IBAction)ckSelected:(id)sender {
    
    [_scaleWeight3 setAlpha:1];
    [_infoLabel setAlpha:0];
    
    //enable printing
    [_printButton setAlpha:1];
    
    //hide all otehr weight views
    [_scaleWeight2 setAlpha:0];
    [_scaleWeight4 setAlpha:0];
    [_scaleWeight5 setAlpha:0];
    [_scaleWeight6 setAlpha:0];
    [_scaleWeight7 setAlpha:0];
    [_scaleWeight8 setAlpha:0];
    [_scaleWeight setAlpha:0];
    
    
    _isCookies = TRUE;
    
    _pricePerGram = 8.21;
    
    _isBlue=FALSE;
    _isPurple=FALSE;
    _isGirlScout=FALSE;
    _isSour=FALSE;
    _isOG=FALSE;
    _isGreen=FALSE;
    _isLights=FALSE;
    

    
}
- (IBAction)nlSelected:(id)sender {
    
    [_scaleWeight5 setAlpha:1];
    [_infoLabel setAlpha:0];
    
    //enable printing
    [_printButton setAlpha:1];
    
    //hide all otehr weight views
    [_scaleWeight2 setAlpha:0];
    [_scaleWeight3 setAlpha:0];
    [_scaleWeight4 setAlpha:0];
    [_scaleWeight6 setAlpha:0];
    [_scaleWeight7 setAlpha:0];
    [_scaleWeight8 setAlpha:0];
    [_scaleWeight setAlpha:0];
    
    
    _isLights = TRUE;
    
    _pricePerGram = 7.11;
    
    _isBlue=FALSE;
    _isPurple=FALSE;
    _isGirlScout=FALSE;
    _isSour=FALSE;
    _isOG=FALSE;
    _isGreen=FALSE;
    _isCookies=FALSE;
    
}

-(void)sendDataToDisplay{
    
    ISDCBBuilder *displayBuilder = [StarIoExt createDisplayCommandBuilder:StarIoExtDisplayModelSCD222];
    [displayBuilder appendClearScreen];
    [displayBuilder appendSpecifiedPosition:1 y:1];
    [displayBuilder appendData:(NSData *)[@"Total: " dataUsingEncoding:NSASCIIStringEncoding]];
    [displayBuilder appendData:(NSData *)[_priceToPrint dataUsingEncoding:NSASCIIStringEncoding]];
    
    
    NSData *commands = [displayBuilder.passThroughCommands copy];
    
    [_starIoExtManager.lock lock];
    
    [Communication sendCommands:commands port:_starIoExtManager.port completionHandler:^(BOOL result, NSString *title, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // do nothing, continue
            [_starIoExtManager.lock unlock];
        });
    }];
    
}

@end
