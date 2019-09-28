#include <stdio.h>
// sizeof
// snprintf
// NULL

#include <stdlib.h>
// malloc

#include <string.h>
// memset

#include "IsBigEndian.h"

#ifndef GET_INTERNAL_HEX_FROM_OPERAND_H
#define GET_INTERNAL_HEX_FROM_OPERAND_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

extern char* getInternalHexFromDouble(double val, unsigned char* len);
extern char* getInternalHexFromFloat(float val, unsigned char* len);
extern char* getInternalHexFromLong(long val, unsigned char* len);
extern char* getInternalHexFromOperand(unsigned char* val, unsigned char bytesOfVal, unsigned char* len);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif // !GET_INTERNAL_HEX_FROM_OPERAND_H


//Function Prototypes
char* getInternalHexFromDouble(double val, unsigned char* len);
char* getInternalHexFromFloat(float val, unsigned char* len);
char* getInternalHexFromLong(long val, unsigned char* len);
char* getInternalHexFromOperand(unsigned char* val, unsigned char bytesOfVal, unsigned char* len);
static unsigned char writeHexfromChar(char* toWrite, unsigned char ch);
static char getCharFrom4Bits(unsigned char bits);


//
//1st�����̓����\��(Hex��)�𕶎���ŕԂ�
//2nd�����ɂ͕����񒷂�����
//
//�ȉ��̏ꍇ��NULL��Ԃ�
//�E2nd������NULL�̏ꍇ
//�E��������i�[���郁�����m�ێ��s�̏ꍇ
//
char* getInternalHexFromDouble(double val, unsigned char* len) {

	return getInternalHexFromOperand((unsigned char*)&val, sizeof(val), len);

}

//
//1st�����̓����\��(Hex��)�𕶎���ŕԂ�
//2nd�����ɂ͕����񒷂�����
//
//�ȉ��̏ꍇ��NULL��Ԃ�
//�E2nd������NULL�̏ꍇ
//�E��������i�[���郁�����m�ێ��s�̏ꍇ
//
char* getInternalHexFromFloat(float val, unsigned char* len) {

	return getInternalHexFromOperand((unsigned char*)&val, sizeof(val), len);

}

//
//1st�����̓����\��(Hex��)�𕶎���ŕԂ�
//2nd�����ɂ͕����񒷂�����
//
//�ȉ��̏ꍇ��NULL��Ԃ�
//�E2nd������NULL�̏ꍇ
//�E��������i�[���郁�����m�ێ��s�̏ꍇ
//
char* getInternalHexFromLong(long val, unsigned char* len) {

	return getInternalHexFromOperand((unsigned char*)&val, sizeof(val), len);

}

//���ʊ֐�
char* getInternalHexFromOperand(unsigned char* val, unsigned char bytesOfVal, unsigned char* len) {

	//�ϐ��錾
	unsigned char   bytesToAlloc;     //�ԋp�������Byte��
	         char   relativeAddress;  //�A�h���X���ǂݍ��݃��[�v�p�J�E���^
	         char*  hexStr;           //�ԋp������
	unsigned char   indexOfHexStr;    //�ԋp������Q�Ɨp
	         char   addressDirection; //�A�h���X�ǂݍ��ݕ���
	unsigned char   loopLimit;        //���[�v����p

	//�����`�F�b�N
	if (len == NULL) {
		return NULL;
	}

	bytesToAlloc = bytesOfVal * 2 + 1; //1�o�C�g��2�����ŕ\�������(+1 �͕�����Ō��'\0'�p)

	//Alloc
	hexStr = (char*)malloc(bytesToAlloc);
	if (hexStr == NULL) { //�������m�ێ��s��
		return NULL;
	}

	memset(hexStr, '\0', bytesToAlloc); //'\0'�ŏ�����

	//Address�ǂݍ��ݕ���
	if (isBigEndian()) { //Big Endian�̏ꍇ
		addressDirection = 1;
		relativeAddress = 0u; //�ǂݍ��݊J�n�ʒu�͍ŏ�Address����

	}else { //Little Endian�̏ꍇ
		addressDirection = -1;
		relativeAddress = (bytesOfVal - 1u); //�ǂݍ��݊J�n�ʒu�͍ő�Address����

	}
	
	//�����񐶐�
	loopLimit = bytesToAlloc - 1;
	for (indexOfHexStr = 0; indexOfHexStr < loopLimit ; indexOfHexStr += 2) {
		writeHexfromChar(&hexStr[indexOfHexStr], val[relativeAddress]); //2�������ɋL�^
		relativeAddress += addressDirection;

	}

	*len = bytesToAlloc;
	return hexStr;
}

//
//2nd������Bit�\����hex������1st�����ɕԂ�
//�I������0��Ԃ�
//2nd������NULL�̏ꍇ�́A1��Ԃ��B
//
static unsigned char writeHexfromChar(char* toWrite, unsigned char ch) {

	//�����`�F�b�N
	if (toWrite == NULL) {
		return 1;
	}

	//���4�r�b�g�擾
	toWrite[0] = getCharFrom4Bits(ch >> 4);

	//����4�r�b�g�擾
	toWrite[1] = getCharFrom4Bits(ch & 0xF);

	return 0;
}


//
//0~16�̐��l����hex�\��������Ԃ�
//0~17�ȊO���w�肳�ꂽ�ꍇ�́A'G'��Ԃ�
//
static char getCharFrom4Bits(unsigned char bits) {

	char chToRet;

	chToRet = 'G'; //���ʕs�\��ݒ�(��

	if (0u <= bits && bits < 10u) { //'0'~'9'�̎�
		chToRet = '0' + bits;

	}
	else if (10u <= bits && bits <= 16u) { //'A'~'F'�̎�
		chToRet = 'A' + bits - 10u;

	}

	return chToRet;
}
