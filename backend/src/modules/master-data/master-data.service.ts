import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma/prisma.service';
import {
    CreateDistrictDto,
    CreateInterestCategoryDto,
    CreateInterestDto,
    CreateLanguageDto,
    CreateProvinceDto,
    CreateServiceTypeDto,
    CreateTalentCategoryDto,
    CreateTalentDto,
    UpdateDistrictDto,
    UpdateInterestDto,
    UpdateLanguageDto,
    UpdateProvinceDto,
    UpdateServiceTypeDto,
    UpdateTalentDto,
} from './dto';

@Injectable()
export class MasterDataService {
  private readonly logger = new Logger(MasterDataService.name);

  constructor(private readonly prisma: PrismaService) {}

  // ==================== Provinces ====================

  async getProvinces(includeInactive = false) {
    return this.prisma.province.findMany({
      where: includeInactive ? {} : { isActive: true },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      include: {
        _count: { select: { districts: true } },
      },
    });
  }

  async getProvinceById(id: string) {
    const province = await this.prisma.province.findUnique({
      where: { id },
      include: {
        districts: {
          where: { isActive: true },
          orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
        },
      },
    });
    if (!province) throw new NotFoundException('Province not found');
    return province;
  }

  async createProvince(dto: CreateProvinceDto) {
    return this.prisma.province.create({ data: dto });
  }

  async updateProvince(id: string, dto: UpdateProvinceDto) {
    return this.prisma.province.update({ where: { id }, data: dto });
  }

  async deleteProvince(id: string) {
    await this.prisma.province.delete({ where: { id } });
    return { message: 'Province deleted' };
  }

  // ==================== Districts ====================

  async getDistricts(provinceId?: string, includeInactive = false) {
    return this.prisma.district.findMany({
      where: {
        ...(provinceId && { provinceId }),
        ...(includeInactive ? {} : { isActive: true }),
      },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      include: { province: { select: { id: true, name: true, code: true } } },
    });
  }

  async getDistrictsByProvince(provinceId: string) {
    return this.prisma.district.findMany({
      where: { provinceId, isActive: true },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });
  }

  async createDistrict(dto: CreateDistrictDto) {
    return this.prisma.district.create({
      data: dto,
      include: { province: { select: { id: true, name: true } } },
    });
  }

  async updateDistrict(id: string, dto: UpdateDistrictDto) {
    return this.prisma.district.update({ where: { id }, data: dto });
  }

  async deleteDistrict(id: string) {
    await this.prisma.district.delete({ where: { id } });
    return { message: 'District deleted' };
  }

  // ==================== Interest Categories ====================

  async getInterestCategories(includeInactive = false) {
    return this.prisma.interestCategory.findMany({
      where: includeInactive ? {} : { isActive: true },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      include: {
        interests: {
          where: includeInactive ? {} : { isActive: true },
          orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
        },
      },
    });
  }

  async createInterestCategory(dto: CreateInterestCategoryDto) {
    return this.prisma.interestCategory.create({ data: dto });
  }

  // ==================== Interests ====================

  async getInterests(categoryId?: string, includeInactive = false) {
    return this.prisma.interest.findMany({
      where: {
        ...(categoryId && { categoryId }),
        ...(includeInactive ? {} : { isActive: true }),
      },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      include: { category: { select: { id: true, name: true } } },
    });
  }

  async createInterest(dto: CreateInterestDto) {
    return this.prisma.interest.create({
      data: dto,
      include: { category: { select: { id: true, name: true } } },
    });
  }

  async updateInterest(id: string, dto: UpdateInterestDto) {
    return this.prisma.interest.update({ where: { id }, data: dto });
  }

  async deleteInterest(id: string) {
    await this.prisma.interest.delete({ where: { id } });
    return { message: 'Interest deleted' };
  }

  // ==================== Talent Categories ====================

  async getTalentCategories(includeInactive = false) {
    return this.prisma.talentCategory.findMany({
      where: includeInactive ? {} : { isActive: true },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      include: {
        talents: {
          where: includeInactive ? {} : { isActive: true },
          orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
        },
      },
    });
  }

  async createTalentCategory(dto: CreateTalentCategoryDto) {
    return this.prisma.talentCategory.create({ data: dto });
  }

  // ==================== Talents ====================

  async getTalents(categoryId?: string, includeInactive = false) {
    return this.prisma.talent.findMany({
      where: {
        ...(categoryId && { categoryId }),
        ...(includeInactive ? {} : { isActive: true }),
      },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      include: { category: { select: { id: true, name: true } } },
    });
  }

  async createTalent(dto: CreateTalentDto) {
    return this.prisma.talent.create({
      data: dto,
      include: { category: { select: { id: true, name: true } } },
    });
  }

  async updateTalent(id: string, dto: UpdateTalentDto) {
    return this.prisma.talent.update({ where: { id }, data: dto });
  }

  async deleteTalent(id: string) {
    await this.prisma.talent.delete({ where: { id } });
    return { message: 'Talent deleted' };
  }

  // ==================== Languages ====================

  async getLanguages(includeInactive = false) {
    return this.prisma.language.findMany({
      where: includeInactive ? {} : { isActive: true },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });
  }

  async createLanguage(dto: CreateLanguageDto) {
    return this.prisma.language.create({ data: dto });
  }

  async updateLanguage(id: string, dto: UpdateLanguageDto) {
    return this.prisma.language.update({ where: { id }, data: dto });
  }

  async deleteLanguage(id: string) {
    await this.prisma.language.delete({ where: { id } });
    return { message: 'Language deleted' };
  }

  // ==================== Service Types ====================

  async getServiceTypes(includeInactive = false) {
    return this.prisma.serviceType.findMany({
      where: includeInactive ? {} : { isActive: true },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });
  }

  async createServiceType(dto: CreateServiceTypeDto) {
    return this.prisma.serviceType.create({
      data: {
        code: dto.code,
        name: dto.name,
        nameVi: dto.nameVi ?? dto.name,
        description: dto.description,
        icon: dto.icon,
        sortOrder: dto.sortOrder ?? 0,
        isActive: dto.isActive ?? true,
      },
    });
  }

  async updateServiceType(id: string, dto: UpdateServiceTypeDto) {
    return this.prisma.serviceType.update({
      where: { id },
      data: dto,
    });
  }

  async deleteServiceType(id: string) {
    await this.prisma.serviceType.delete({ where: { id } });
    return { message: 'Service type deleted' };
  }

  // ==================== Combined Data for Profile Edit ====================

  /**
   * Get all master data needed for profile editing
   * Returns provinces, interests, talents, languages in one call
   */
  async getProfileMasterData() {
    const [provinces, interests, talents, languages] = await Promise.all([
      this.getProvinces(),
      this.getInterests(),
      this.getTalents(),
      this.getLanguages(),
    ]);

    return {
      provinces,
      interests,
      talents,
      languages,
    };
  }

  /**
   * Get all master data needed for partner registration
   * Returns provinces, serviceTypes in one call
   */
  async getPartnerMasterData() {
    const [provinces, serviceTypes] = await Promise.all([
      this.getProvinces(),
      this.getServiceTypes(),
    ]);

    return {
      provinces,
      serviceTypes,
    };
  }
}
