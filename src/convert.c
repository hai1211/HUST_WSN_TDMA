#include <stdio.h>
#include "Huffman/Huffman.c"

uint16_t convertHexToDemi(nx_uint16_t temperature){
	//int count;
	float realnum;
	//double d = 0, remain = 0, result = 0;
	printf("%u \n", temperature);
	//realnum = -39.6 + 0.01 * temperature;
    return -39.6 + 0.01 * temperature;
}

void printfFloat(float toBePrinted) {
     uint32_t fi, f0, f1, f2;
     char c;
     float f = toBePrinted;

     if (f<0){
       c = '-'; f = -f;
     } else {
       c = ' ';
     }

     // integer portion.
     fi = (uint32_t) f;

     // decimal portion...get index for up to 3 decimal places.
     f = f - ((float) fi);
     f0 = f*10;   f0 %= 10;
     f1 = f*100;  f1 %= 10;
     f2 = f*1000; f2 %= 10;
     printf("%c%ld.%d%d%d\n", c, fi, (uint8_t) f0, (uint8_t) f1,  (uint8_t) f2);
}
void testHuffman(){
    TreeNode * root = createEmptyTree();
    TreeNode *root2 = createEmptyTree();

    int i;
    float *f;
    float data[5] = {0.1, 0.2, 0.2, 0.2, 0.1};

    char *s = encoder(data, 5, root);
    f = decoder(s, root2);

    printf("%s\n", s);
    for (i = 0; i < 5; i++){
        printf("%f ", f[i]);
    }
    printf("\n");
}