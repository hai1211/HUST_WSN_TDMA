#include "group.h"
#include <math.h>

const float GROUP0[1] = {0.0};
const float GROUP1[1] = {0.1};
const float GROUP2[2] = {0.2,0.3};
const float GROUP3[4] = {0.4,0.5,0.6,0.7};
const float GROUP4[8] = {0.8,0.9,1.0,1.1,1.2,1.3,1.4,1.5};
const float GROUP5[16] = {1.6,1.7,1.8,1.9,2,2.1,2.2,2.3,2.4,2.5,2.6,2.7,2.8,2.9,3,3.1};
const float GROUP6[32] = {3.2,3.3,3.4,3.5,3.6,3.7,3.8,3.9,4,4.1,4.2,4.3,4.4,4.5,4.6,4.7,
                    4.8,4.9,5,5.1,5.2,5.3,5.4,5.5,5.6,5.7,5.8,5.9,6,6.1,6.2,6.3};
const float GROUP7[64] =  {
                    6.4,6.5,6.6,6.7,6.8,6.9,
                    7.0,7.1,7.2,7.3,7.4,7.5,7.6,7.7,7.8,7.9,
                    8.0,8.1,8.2,8.3,8.4,8.5,8.6,8.7,8.8,8.9,
                    9.0,9.1,9.2,9.3,9.4,9.5,9.6,9.7,9.8,9.9,
                    10.0,10.1,10.2,10.3,10.4,10.5,10.6,10.7,10.8,10.9,
                    11.0,11.1,11.2,11.3,11.4,11.5,11.6,11.7,11.8,11.9,
                    12.0,12.1,12.2,12.3,12.4,12.5,12.6,12.7
                    };
const float *GROUPS[] = {GROUP0, GROUP1, GROUP2, GROUP3, GROUP4, GROUP5, GROUP6, GROUP7};

int check(float diff, const float group[], int size){
  for(int i = 0; i < size; i++){
    if(diff == group[i]) return i;
  }
  return -1;
}

float absFloat(float diff){
  if(diff >= 0)
    return diff;
  else
    return -diff;
}

Group * fromDiffToGroup(float diff) {
    Group * g;

    g = (Group*)malloc(sizeof(Group));

    float Diff = absFloat(diff);

    if(Diff == 0.0){
        g->number = GROUP_0;
        g->size = 1;
    }
    if(Diff == (float)0.1){
        g->number = GROUP_1;
        g->size = 1;
    }
    if(check(Diff, GROUP2, 2) != -1){
        g->number = GROUP_2;
        g->size = 2;
    }
    if(check(Diff, GROUP3, 4) != -1){
        g->number = GROUP_3;
        g->size = 4;
    }
    if(check(Diff, GROUP4, 8) != -1){
        g->number = GROUP_4;
        g->size = 8;
    }
    if(check(Diff, GROUP5, 16) != -1){
        g->number = GROUP_5;
        g->size = 16;
    }
    if(check(Diff, GROUP6, 32) != -1){
        g->number = GROUP_6;
        g->size = 32;
    }
    if(check(Diff, GROUP7, 64) != -1){
        g->number = GROUP_7;
        g->size = 64;
    }

    g->difference = GROUPS[g->number];
    return g;
}

float getDataByIndex(int index, Group * g){
    if(index <= g->size){
        return -g->difference[index];
    }
    else{
        return g->difference[index - g->size -1];
    }
}

int getGroupBinaryLength(Group * g){
    int length;
    length = log2(g->size * 2);
    return length;
}

// int main(){
//    Group * g;
//    g = fromDiffToGroup(1.8);
//    printf("Group number %d\n", g->number);
//    printf("Group size: %d\n", g->size);
//    //cout << g->number << endl;
//    int index = 11;
//    float data = getDataByIndex(index,g);
//    printf("Data %f \n", data);
//    //cout << data << endl;
// }
