/*
  Warnings:

  - A unique constraint covering the columns `[code]` on the table `interest_categories` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[code]` on the table `talent_categories` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `code` to the `interest_categories` table without a default value. This is not possible if the table is not empty.
  - Added the required column `code` to the `talent_categories` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "interest_categories" ADD COLUMN     "code" TEXT NOT NULL,
ADD COLUMN     "color" TEXT;

-- AlterTable
ALTER TABLE "talent_categories" ADD COLUMN     "code" TEXT NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "interest_categories_code_key" ON "interest_categories"("code");

-- CreateIndex
CREATE UNIQUE INDEX "talent_categories_code_key" ON "talent_categories"("code");
