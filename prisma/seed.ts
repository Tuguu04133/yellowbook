import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // Clear existing data
  await prisma.yellowBook.deleteMany();

  // Create seed data
  const yellowBooks = await Promise.all([
    prisma.yellowBook.create({
      data: {
        businessName: 'Улаанбаатар Ресторан',
        category: 'Restaurant',
        phoneNumber: '+976-7011-1234',
        address: 'Сүхбаатарын талбай, Улаанбаатар',
        description: 'Монгол болон олон улсын хоолны сонголт',
        website: 'https://ulaanbaatar-restaurant.mn',
      },
    }),
    prisma.yellowBook.create({
      data: {
        businessName: 'Тэнгэр Эмнэлэг',
        category: 'Hospital',
        phoneNumber: '+976-7012-5678',
        address: '3-р хороо, Баянгол дүүрэг',
        description: 'Ерөнхий эмнэлгийн үйлчилгээ 24/7',
        website: 'https://tenger-hospital.mn',
      },
    }),
    prisma.yellowBook.create({
      data: {
        businessName: 'Nomad IT Solutions',
        category: 'Technology',
        phoneNumber: '+976-8888-9999',
        address: 'Центральный Тауэр, Сүхбаатар дүүрэг',
        description: 'Програм хангамж хөгжүүлэлт ба IT зөвлөх үйлчилгээ',
        website: 'https://nomad-it.mn',
      },
    }),
    prisma.yellowBook.create({
      data: {
        businessName: 'Говь Авто Засвар',
        category: 'Auto Repair',
        phoneNumber: '+976-9900-1122',
        address: 'Яармаг, Баянзүрх дүүрэг',
        description: 'Бүх төрлийн автомашин засвар үйлчилгээ',
        website: '',
      },
    }),
    prisma.yellowBook.create({
      data: {
        businessName: 'Шинэ Өглөө Сургууль',
        category: 'Education',
        phoneNumber: '+976-7777-3344',
        address: '12-р хороо, Хан-Уул дүүрэг',
        description: 'Дунд боловсролын сургууль, 1-12-р анги',
        website: 'https://shine-ugluu.edu.mn',
      },
    }),
    prisma.yellowBook.create({
      data: {
        businessName: 'Эрдэнэт Үсчин',
        category: 'Beauty Salon',
        phoneNumber: '+976-9911-2233',
        address: 'Энхтайваны өргөн чөлөө',
        description: 'Үс засалт, өнгөлөх, гоо засал',
        website: '',
      },
    }),
    prisma.yellowBook.create({
      data: {
        businessName: 'Мөнх Тэнгэр Номын Дэлгүүр',
        category: 'Bookstore',
        phoneNumber: '+976-7011-9988',
        address: 'Их Тойруу 29, Сүхбаатар дүүрэг',
        description: 'Монгол болон гадаад ном, сурах бичиг',
        website: 'https://munkh-tengger-books.mn',
      },
    }),
  ]);

  console.log(`✅ Created ${yellowBooks.length} yellow book entries`);
  
  yellowBooks.forEach((book) => {
    console.log(`  📘 ${book.businessName} (${book.category})`);
  });
}

main()
  .catch((e) => {
    console.error('❌ Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
