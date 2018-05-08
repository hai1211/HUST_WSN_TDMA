/*
 * HuffmanTree.h
 *
 *  Created on: Mar 8, 2016
 *      Author: Administrator
 */

#ifndef HUFFMANTREE_H_
#define HUFFMANTREE_H_

#define BCD_CODE_LENGTH 16

#include "treeNode.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>



void initialize(TreeNode *tree);
TreeNode* search(TreeNode *tree,TreeNode *node);
TreeNode* search_nyt(TreeNode *tree);
void buildCode(TreeNode *tree);
void printCode(TreeNode *tree);
char * ConvertToBinary(int n, int length);
int ConvertToDecima(char * BinaryCode);
char * ConvertToBCD(float diff);
float BCDtoDecima(char * BCDcode);
char * traverse(TreeNode *tree, float diff);
char * suffixCode(float diff);
void addNode(TreeNode *tree, float diff);
int reBalance_Step(TreeNode *tree);
void reBalance(TreeNode *tree);
void printTree(TreeNode *tree);
//float* createDiffArr(float *currentData, float previousData);
char * encoder(float *Data, int length, TreeNode *root);
float * decoder(char * code, TreeNode *root);


#endif /* HUFFMANTREE_H_ */
