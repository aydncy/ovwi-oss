double calculateBill(int used) {
  const free = 1000;
  const pricePerUnit = 0.05;

  if (used <= free) return 0;

  return (used - free) * pricePerUnit;
}








