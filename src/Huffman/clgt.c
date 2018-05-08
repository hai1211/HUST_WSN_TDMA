#include <stdio.h>
#include "HuffmanTree.h"

void main(){
    TreeNode * root = createEmptyTree();
    float data[5] = {0.1, 0.2, 0.1, 0.1, 0.2};

    char * s = encoder(data, 5, root);
    printf("%s\n", s);
}