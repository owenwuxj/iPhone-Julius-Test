//
//  Julius.m
//  JuliusSample
//
//  Created by Watanabe Toshinori on 11/01/15.
//  Copyright 2011 FLCL.jp. All rights reserved.
//

#import "Julius.h"
#import "JuliusSampleAppDelegate.h"

#define charLength 60000

@implementation Julius

@synthesize delegate;

#pragma mark -
#pragma mark Julis Callback methods

static void output_result(Recog *recog_, void *data) {

	WORD_INFO *winfo;
	WORD_ID *seq;
    
	int seqnum;
	int n,i,j;
    
	Sentence *s;
	RecogProcess *r;

	NSMutableArray *words = [NSMutableArray array];//The output string array.
    NSMutableArray *bounds = [NSMutableArray array];//The boundaries/durations;
	
    // *********  Start  *************
    //    jbyteArray jbarray;
    //    int len = 0;
    //    char *p;
    
    char result[charLength]; // increased from 1024 --James Salsman DOUBLE CHECK THIS
    result[0]='\0';
    
//    float *confs; // added for per-word confidence scores
    char sbuf[100], pbuf[10]; // added for sprintf buffer, and phoneme copy buffer
    SentenceAlign *alignment; // added for endpoints; may need a separate alignment call to populate!!!
    // ***********  End  *************

	for(r = recog_->process_list; r; r = r->next) {
		
		if (! r->live) continue;
		
//		if (r->result.status < 0) continue;
//        sprintf(sbuf, "<recogresults status='%d' frames='%d' subresults='%d'>\n",
//                r->result.status, r->result.num_frame, r->result.sentnum);
        NSLog(@"<recogresults status='%d' frames='%d' subresults='%d'>\n", r->result.status, r->result.num_frame, r->result.sentnum);
        strcat(result, sbuf);
        
        if (r->result.status < 0) {
            strcat(result, "</recogresults>\n");
            continue;
        }

        
		winfo = r->lm->winfo;
		for(n = 0; n < r->result.sentnum; n++) {
			s = &(r->result.sent[n]);
			seq = s->word;
			seqnum = s->word_num;

			for(i = 0; i < seqnum; i++) {
                if (winfo->woutput[seq[i]]) {
                    [words addObject:[NSString stringWithCString:winfo->woutput[seq[i]] encoding:NSUTF8StringEncoding]];
                }
			}
            
//            NSLog(@"seq:%d %d",seq[0],n);
//            NSLog(@"seqnum: %d", seqnum);
//            NSLog(@"sentence:%@ recogProcess:%@", s,r);
            
            // ***********  Start  *************
            
//            if ( seqnum>0 &&
//                ( strchr(winfo->woutput[seq[0]], '-')
//                 || strchr(winfo->woutput[seq[0]], '+') ) ) {
////                    sprintf(sbuf, "  <neighbors phonemes='%d'>\n", seqnum);
//                    NSLog(@"  <neighbors phonemes='%d'>\n", seqnum);
//                    strcat(result, sbuf);
//                    
//                    for(i=0; i<seqnum; i++) {
//                        char *c = winfo->woutput[seq[i]];
//                        if (strchr(c, '-')) {
////                            sprintf(sbuf, "    <neighbor expected='%s' detected='%s' />", //\n
////                                    strsep(&c, "-"), c); // god i hope that works
//                            NSLog(@"    <neighbor expected='%s' detected='%s' />", strsep(&c, "-"), c);
//                            strcat(result, sbuf);
//                        } else {
////                            sprintf(sbuf, "    <expected phoneme='%s' />",strsep(&c, "+"));
//                            NSLog(@"    <expected phoneme='%s' />",strsep(&c, "+"));
//                            strcat(result, sbuf);
//                        }
//                    }
//                    strcat(result, "  </neighbors>\n");
//                }
//            else {
//                    sprintf(sbuf, "  <neighbors phonemes='%d'>\n", seqnum);
                NSLog(@"  <neighbors phonemes='%d'>\n", seqnum);
                strcat(result, sbuf);
            
                for(i=0; i<seqnum; i++) {
//                    char *c = winfo->woutput[seq[i]];
//                    if (strchr(c, '-')) {
//                        for (j=0; c[j] != '-'; j++) {
//                            pbuf[j] = c[j];
//                        }
//                        pbuf[j] = '\0';
//                        NSLog(@"    <neighbor expected='%s'", pbuf);
//                        strcat(result, sbuf);
//                        NSLog(@" detected='%s />'",c+j+1);
//                        strcat(result, sbuf);
//                    } else {
//                        for (j=0; c[j] != '+'; j++) {
//                            pbuf[j] = c[j];
//                        }
//                        pbuf[j] = '\0';
//                        NSLog(@"    <expected phoneme='%s' />", pbuf);
//                        strcat(result, sbuf);
//                    }
                }
            
                strcat(result, "  </neighbors>\n");
            
                if (s->align) {
                    for (alignment=s->align; alignment; alignment=alignment->next) {
                        seqnum = alignment->num;
                        if (alignment->unittype == PER_WORD) {
                            NSLog(@"  <alignment phonemes='%d'>\n", seqnum);
                            strcat(result, sbuf);
                            
                            for(i=0; i<seqnum; i++) {
                                NSLog(@"    <segment phoneme='%s' duration='%d' logprob='%.2f' />", //\n
                                        strsep(&(winfo->woutput[alignment->w[i]]), "x"), // trim trailing 'x'
                                        alignment->end_frame[i] - alignment->begin_frame[i], // duration in frames
                                        alignment->avgscore[i]);
                                strcat(result, sbuf);
                                
                                [bounds addObject:[NSNumber numberWithInt:(alignment->end_frame[i] - alignment->begin_frame[i])]];//Owen
                            }
                        }
                        strcat(result, "  </alignment>\n");
                        NSLog(@"  </alignment>\n");
                    } // there better be only one alignment per non-neighbor list
                }
            }
//        }
        NSLog(@"</recogresults>\n");
        strcat(result, "</recogresults>\n");
    }
    
//    len = strlen(result);
//    jbarray = (*genv)->NewByteArray(genv, len);
//    (*genv)->SetByteArrayRegion(genv, jbarray, 0, len, (jbyte*)result);
//    
//    jclass jcls = (*genv)->GetObjectClass(genv, *gobj);
//    jmethodID jmethod = (*genv)->GetMethodID(genv, jcls, "callback", "([B)V");
//    (*genv)->CallVoidMethod(genv, *gobj, jmethod, jbarray);
//    (*genv)->DeleteLocalRef(genv, jbarray);
    
//		}
//	}
    // ***********  End  *************

    // Write a *.txt file to temp folder
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yMMddHHmmss"];
    NSString *fileName = [NSString stringWithFormat:@"%@.txt", [formatter stringFromDate:[NSDate date]]];
    
	NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    NSString *zStr = [NSString stringWithFormat:@"%s",result];
    
    NSError *err;
    [zStr writeToFile:filePath atomically:YES encoding:NSASCIIStringEncoding error:&err];
    
    if (err) {
        NSLog(@"Writing to txt file error: %@",err);
    }
    
    NSLog(@"Txt File Path is: %@",filePath);

    // Callback delegate.
	if (data) {
		Julius *julius = (__bridge id)data;
		if (julius.delegate) {
			[julius.delegate callBackResult:[NSArray arrayWithArray:words] withBounds:bounds];
		}
	}
}

#pragma mark -
#pragma mark Initialize

- (id)init {
	if (self = [super init]) {
		
		Jconf *jconf;
		
//        NSString *temp = [JuliusSampleAppDelegate ]
        
		/* create a configuration variables container */
		NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"jconf"];
		jconf = j_jconf_new();
		if (j_config_load_file(jconf, (char *)[path UTF8String]) == -1) {
			NSLog(@"Error in loading file");
			return nil;
		}
		
		if (j_jconf_finalize(jconf) == FALSE) {
			NSLog(@"Error in finalize");
			return nil;
		}
		
		/* create a recognition instance */
		recog = j_recog_new();
        
		/* assign configuration to the instance */
		recog->jconf = jconf;
        
		/* load all files according to the configurations */
		if (j_load_all(recog, jconf) == FALSE) {
			NSLog(@"Error in loadn model");
			return nil;
		}
		
		/* checkout for recognition: build lexicon tree, allocate cache */
		if (j_final_fusion(recog) == FALSE) {
			NSLog(@"Error while setup work area for recognition");
			j_recog_free(recog);
			return nil;
		}
		
		if (j_adin_init(recog) == FALSE) {
			NSLog(@"Error while adin init");
			j_recog_free(recog);
			return nil;
		}
		
		/* output system information to log */
//		j_recog_info(recog);
		
		/* if no grammar specified on startup, start with pause status */
		{
			RecogProcess *r;
			boolean ok_p;
			ok_p = TRUE;
			for(r=recog->process_list;r;r=r->next) {
				if (r->lmtype == LM_DFA) {
					if (r->lm->winfo == NULL) { /* stop when no grammar found */
						j_request_pause(recog);
					}
				}
			}
		}
		
		callback_add(recog, CALLBACK_RESULT, output_result, (__bridge void *)(self));
	}
	
	return self;
}


#pragma mark -
#pragma mark Actions

- (void)recognizeRawFileAtPath:(NSString *)path {
	
	int ret = j_open_stream(recog, (char *)[path UTF8String]);
	if (ret == -1) {
		NSLog(@"Error in open stream");
		return;
	}
	
	ret = j_recognize_stream(recog);
	if (ret == -1) {
		NSLog(@"Error in regocnize stream");
		return;
	}
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	j_recog_free(recog);

}

@end
