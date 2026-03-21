-- CreateEnum - Education
CREATE TYPE "Education" AS ENUM ('PRIMARY', 'SECONDARY', 'HIGH_SCHOOL', 'VOCATIONAL', 'BACHELOR', 'MASTER', 'DOCTORATE', 'OTHER');

-- CreateEnum - SmokingHabit
CREATE TYPE "SmokingHabit" AS ENUM ('NEVER', 'SOMETIMES', 'REGULARLY', 'QUIT', 'NOT_SPECIFIED');

-- CreateEnum - DrinkingHabit
CREATE TYPE "DrinkingHabit" AS ENUM ('NEVER', 'SOCIALLY', 'REGULARLY', 'HEAVILY', 'QUIT', 'NOT_SPECIFIED');

-- AlterTable - Add columns to profiles
ALTER TABLE "profiles" ADD COLUMN "education" "Education",
ADD COLUMN "smoking_habit" "SmokingHabit",
ADD COLUMN "drinking_habit" "DrinkingHabit";
