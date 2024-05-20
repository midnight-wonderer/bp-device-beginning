#include "stm32f1xx.h"

static void config_timer(void);
static void config_io(void);
static void tim2_handler(void);

int main(void) {
	config_io();
	config_timer();
	for(;;) {
		if(READ_BIT(TIM2->SR, TIM_SR_UIF)) {
			CLEAR_BIT(TIM2->SR, TIM_SR_UIF);
			tim2_handler();
		}
	}
}

static void tim2_handler(void) {
	if(READ_BIT(GPIOC->ODR, GPIO_ODR_ODR13))
		SET_BIT(GPIOC->BSRR, GPIO_BSRR_BR13);
	else
		SET_BIT(GPIOC->BSRR, GPIO_BSRR_BS13);
}

static void config_timer(void) {
	MODIFY_REG(TIM2->PSC, TIM_PSC_PSC, 2400 - 1);
	MODIFY_REG(TIM2->ARR, TIM_ARR_ARR, 5000);
	MODIFY_REG(TIM2->CR1, 0, TIM_CR1_ARPE | TIM_CR1_URS | TIM_CR1_CEN);
	TIM2->CNT = 0;
	CLEAR_BIT(TIM2->SR, TIM_SR_UIF);
}

static void config_io(void) {
	MODIFY_REG(GPIOC->CRH, GPIO_CRH_CNF13 | GPIO_CRH_MODE13, GPIO_CRH_CNF13_0 | GPIO_CRH_MODE13_1);
}
