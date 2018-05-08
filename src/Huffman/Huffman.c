#include <stdio.h>
#include <stdlib.h>
#include "definition.h"
#include <string.h>
#include <stdio.h>
#include <math.h>
#include "../libiberty/xmalloc.c"

#define BCD_CODE_LENGTH 16

//Group

typedef struct group {
  const float *difference;
  int number;
  int size;
} Group;

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
    int i;
  for(i = 0; i < size; i++){
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

    //g = (Group*)malloc(sizeof(Group));

    float Diff;
    Diff = absFloat(diff);

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

//Tree Node
typedef struct TreeNode {
  Group * group;
  // int weight = -1;
  // int flag = COMP_NODE;
  int weight;
  int flag;
  struct TreeNode *l_child;
  struct TreeNode *r_child;
  char *huffmanCode;
} TreeNode;

TreeNode * createNYT_TreeNode(){
    TreeNode * node;

    node = (TreeNode*)malloc(sizeof(TreeNode));
    node->group = (Group*)malloc(sizeof(Group));
    node->huffmanCode = malloc(1);

    node->flag = NYT_NODE;
    node->weight = 0;
    node->l_child = NULL;
    node->r_child = NULL;
    node->group->number = -1;

    return node;
}

TreeNode * createNRM_TreeNode(float diff){
    TreeNode * node;

    node = malloc(sizeof(TreeNode));
    node->huffmanCode = malloc(1);

    node->flag = NRM_NODE;
    node->weight = 1;
    node->l_child = 0;
    node->r_child = 0;
    //node->group.fromDiffToGroup(diff);
    node->group = fromDiffToGroup(diff);

    return node;
}

//HuffmanTree

TreeNode * createEmptyTree(){
    TreeNode * root = createNYT_TreeNode();
    root->huffmanCode = "";

    return root;
}

TreeNode * search(TreeNode *root, TreeNode *node) {
    TreeNode *left, *right;
    if (root != NULL) {
        if (root->group->number == node->group->number) {
            //cout << "Node " << node->group.group << " founded." << endl;
            return root;
        } else {
            left = search(root->l_child, node);
            if (left != NULL)
                return left;
            right = search(root->r_child, node);
            if (right != NULL)
                return right;
        }
    } else {
        //cout << "Node " << node->group.group << " not found" << endl;
        return NULL;

    }

}

TreeNode * search_nyt(TreeNode *root) {
    TreeNode *left, *right;
    if (root != NULL) {
        if (root->flag == NYT_NODE) {
            //cout << "NYT node founded." << endl;
            return root;
        } else {
            left = search_nyt(root->l_child);
            if (left != NULL)
                return left;
            right = search_nyt(root->r_child);
            if (right != NULL)
                return right;
        }
    } else {
        //cout << "NYT node not found." << endl;
        return NULL;
    }

}

void buildCode(TreeNode *root) {
    int length = strlen(root->huffmanCode) + 1;
    char * code;

    if (root->l_child) {
        code = malloc(length);

        strcpy(code, root->huffmanCode);
        strcat(code, "0");

        root->l_child->huffmanCode = code;

        buildCode(root->l_child);
    }
    if (root->r_child) {
        code = malloc(length);

        strcpy(code, root->huffmanCode);
        strcat(code, "1");

        root->r_child->huffmanCode = code;

        buildCode(root->r_child);
    }
}

void printCode(TreeNode *root) {
    if (root->l_child == NULL && root->r_child == NULL)
        printf("%d %d %s", root->group->number, root->weight, root->huffmanCode);
    if (root->l_child != NULL)
        printCode(root->l_child);
    if (root->r_child != NULL)
        printCode(root->r_child);
}

char * traverse(TreeNode *root, float diff) {
    char *prefixCode;
    TreeNode *node;

    node = search(root, createNRM_TreeNode(diff));

    if (node == NULL) {
        //printf("node null\n");
        node = search_nyt(root);
    }

    prefixCode = malloc(strlen(node->huffmanCode));
    strcpy(prefixCode, node->huffmanCode);

    return prefixCode;
}

char * ConvertToBinary(int n, int length) {
  char * binaryString = malloc(1), *tmp;
  int size = 0, i, preSize;

  if (n == 0) {
    strcpy(binaryString, "0");
  } else {
    while (n != 0) {
      tmp = strdup(binaryString);
      binaryString = realloc(binaryString, ++size);

      strcpy(binaryString, (n % 2 == 0 ? "0" : "1"));
      strcat(binaryString, tmp);

      n /= 2;
      free(tmp);
    }
  }

  preSize = length - size;

  if (preSize > 0){
    tmp = binaryString;
    binaryString = malloc(length);

    for (i = 0; i < preSize; i++){
      strcat(binaryString, "0");
    }

    strcat(binaryString, tmp);
    free(tmp);
  }

  return binaryString;
}

char * suffixCode(float diff) {
    char * sufCode;
    int index;
    Group *g = fromDiffToGroup(diff);
    int codeLength = getGroupBinaryLength(g);
    int i;
    for (i = 0; i < g->size; i++) {
        if (absFloat(diff) == g->difference[i]) {
            index = i;
            break;
            //cout << index << endl;
        }
    }
    if (diff < 0) {
        sufCode = ConvertToBinary(g->size - index - 1, codeLength);
    }
    if (diff >= 0) {
        sufCode = ConvertToBinary(g->size + index, codeLength);
    }

    return sufCode;
}

int ConvertToDecima(char * binaryCode){
    int i, codeLength = strlen(binaryCode);
    char codeChar;
    int codeNumber, decima = 0;

    for (i = 0; i < codeLength; i++){
        codeChar = binaryCode[codeLength - i - 1];
        codeNumber = codeChar - '0';

        if(codeNumber){
            decima += 1 << i;
        }
    }

    return decima;
}

char * ConvertToBCD(float diff) {
    int n = (int) (diff * 10);

    char *BCDcode = ConvertToBinary(n, BCD_CODE_LENGTH);

    if(diff < 0){
        BCDcode[0] = '1';
    }

    return BCDcode;
}

float BCDtoDecima(char * BCDcode){
    int n;
    float res;
    char first = BCDcode[0];

    if(first == '1'){
        BCDcode[0] = '0';
    }

    n = ConvertToDecima(BCDcode);
    res = (float)n/10;

    if(first == '1')
        return -res;
    else
        return res;
}

void addNode(TreeNode *root, float diff) {
    TreeNode* nyt = createNYT_TreeNode();
    TreeNode* nrm = createNRM_TreeNode(diff);
    TreeNode* temp = search_nyt(root);

    temp->l_child = nyt;
    temp->flag = COMP_NODE;
    temp->weight = -1;
    //temp->group.group = -2;
    temp->r_child = nrm;
    //cout << "New node " << temp->r_child->group.group << endl;

}

int reBalance_Step(TreeNode *root) {
    TreeNode *upper_node = NULL, *lower_node = NULL;
    int upper_weight, lower_weight;

    if(root->r_child){
        upper_node = root->r_child;
        upper_weight = upper_node->weight;
    }

    if(root->l_child && root->l_child->r_child){
        lower_node = root->l_child->r_child;
        lower_weight = lower_node->weight;
    }

    if(upper_node && lower_node){
        //printf("upper node & lower node\n");
        if(lower_weight > upper_weight){
            root->r_child = lower_node;
            root->l_child->r_child = upper_node;
            reBalance_Step(root->l_child);
            return 1;
        }
    }

    return 0;
}

void reBalance(TreeNode *root) {
    int count;
    count = reBalance_Step(root);
    while (count != 0) {
        count = reBalance_Step(root);
    }
    buildCode(root);
}

void printTree(TreeNode *root) {
    //if(tree->l_child == NULL && tree->r_child == NULL)
    // cout << tree->flag << " " << tree->group.group << " " << tree->weight
    //         << endl;
    printf("%d %d %d \n", root->flag, root->group->number, root->weight);
    if (root->l_child != NULL)
        printTree(root->l_child);
    if (root->r_child != NULL)
        printTree(root->r_child);

}

/*float * createDiffArr(float * currentData, float previousData) {
    float *diffArr;
    diffArr = (float *) malloc(currentData.size() * sizeof(float *));
    for (int i = 0; i < currentData.size(); i++) {
        if (i == 0) {
            diffArr[i] = currentData[i] - previousData;
            diffArr[i] = (float) round(diffArr[i] * 10) / 10;
        } else {
            diffArr[i] = currentData[i] - currentData[i - 1];
            diffArr[i] = (float) round(diffArr[i] * 10) / 10;
        }
    }
    return diffArr;
}*/

char * encoder(float *data, int length, TreeNode *root) {
    char *preCode, *sufCode, *code = malloc(0), *tmp;
    TreeNode *temp;
    int i;
    for (i = 0; i < length; i++) {
        temp = createNRM_TreeNode(data[i]);
        temp = search(root, temp);
        if (temp == NULL) {
            preCode = traverse(root, data[i]);
            sufCode = ConvertToBCD(data[i]);

            addNode(root, data[i]);
            reBalance(root);
        } else {
            preCode = traverse(root, data[i]);
            sufCode = suffixCode(data[i]);

            temp->weight += 1;
            reBalance(root);
        }

        code = realloc(code, strlen(code) + strlen(preCode) + strlen(sufCode) + 1);

        strcat(code, preCode);
        strcat(code, sufCode);

        free(preCode);
        free(sufCode);
    }


    return code;
}

float getDataFromBCDCode(char *code){
    char *sufCode;
    float data;
    int decima;

    sufCode = malloc(BCD_CODE_LENGTH + 1);
    memcpy(sufCode, code, BCD_CODE_LENGTH);
    sufCode[BCD_CODE_LENGTH] = '\0';

    decima = ConvertToDecima(suffixCode);
    data = (float) decima / 10;
    free(sufCode);

    return data;
}

float getDataFromCode(Group * group, char *code, int length){
    char * suffCode;
    int index;
    float data;

    suffCode = malloc(length + 1);
    memcpy(suffCode, code, length);
    suffCode[length] = '\0';

    index = ConvertToDecima(suffCode);

    if(index >= group->size){
        index -= group->size;
    }

    data = group->difference[index];

    return data;
}

float * decoder(char * code, TreeNode *root) {
    TreeNode *currentNode;
    //char *sufCode;
    float *dataArray = malloc(sizeof(float)), data;

    int count = 0, codeLength = strlen(code), data_count = 0;
    int sufCodeLength = 0;

    char currentCode = code[count];

    while (count < codeLength){
        currentCode = code[count];
        currentNode = root;

        dataArray = realloc(dataArray, (data_count + 1) * sizeof(float));
        if(currentNode->flag == NYT_NODE){
            data = getDataFromBCDCode(&code[count]);
            dataArray[data_count++] = data;
            addNode(root, data);
            reBalance(root);
            count += BCD_CODE_LENGTH;
        } else if (currentNode->flag == COMP_NODE){
            // Duyet tung ki tu 0
            while(currentCode == '0' && currentNode->flag != NYT_NODE){
                currentNode = currentNode->l_child;
                count++;
                currentCode = code[count];
            }

            if(currentNode->flag == NYT_NODE){
                data = getDataFromBCDCode(&code[count]);
                dataArray[data_count++] = data;
                addNode(root, data);
                reBalance(root);
                count += BCD_CODE_LENGTH;
            } else if(currentNode->flag == COMP_NODE){
                // Doc ki tu 1
                count++;
                currentNode = currentNode->r_child;

                sufCodeLength = getGroupBinaryLength(currentNode->group);
                data = getDataFromCode(currentNode->group, &code[count], sufCodeLength);
                dataArray[data_count++] = data;

                count += sufCodeLength;
                currentNode->weight++;
                reBalance(root);
            }
        }

    printf("group %d\n", root->r_child->group->number);
    }



    return dataArray;
}
