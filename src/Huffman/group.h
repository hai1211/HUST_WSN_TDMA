#include <stdio.h>
#include <stdlib.h>
#include "definition.h"

typedef struct group {
  const float *difference;
  int number;
  int size;
} Group;

int check(float diff, const float group[], int size);
float absFloat(float diff);
Group * fromDiffToGroup(float diff);
float getDataByIndex(int index, Group * g);
int getGroupBinaryLength(Group * g);
