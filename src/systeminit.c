#include "stm32f1xx.h"
#include "system_stm32f1xx.h"
#include <stdint.h>

uint32_t SystemCoreClock = 48e6;

static void config_clock(void);

void SystemInit(void) {
  config_clock();
}

static void config_clock(void) {
  MODIFY_REG(FLASH->ACR, FLASH_ACR_LATENCY, FLASH_ACR_LATENCY_1);
  SET_BIT(RCC->CR, RCC_CR_HSEON);
  while (!READ_BIT(RCC->CR, RCC_CR_HSERDY)) {
    // wait
  }

  MODIFY_REG(RCC->CFGR, RCC_CFGR_PLLMULL, RCC_CFGR_PLLMULL6 | RCC_CFGR_USBPRE | RCC_CFGR_PLLSRC);
  SET_BIT(RCC->CR, RCC_CR_PLLON);
  while (!READ_BIT(RCC->CR, RCC_CR_PLLRDY)) {
    // wait
  }
  MODIFY_REG(RCC->CFGR, RCC_CFGR_SW | RCC_CFGR_PPRE1, RCC_CFGR_SW_PLL | RCC_CFGR_PPRE1_DIV4);
  while (READ_BIT(RCC->CFGR, RCC_CFGR_SWS) != RCC_CFGR_SWS_PLL) {
    // wait
  }
  CLEAR_BIT(RCC->CR, RCC_CR_HSION);
  SET_BIT(RCC->APB1ENR, RCC_APB1ENR_TIM2EN);
  SET_BIT(RCC->APB2ENR, RCC_APB2ENR_IOPCEN);
}
