import { Metadata } from "next";
import { notFound } from "next/navigation";
import PartnerProfileView from "./partner-profile-view";

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:3222/api";

// Type for the partner data returned by the API
interface PartnerData {
  id: string;
  userId: string;
  hourlyRate: number;
  minimumHours: number;
  averageRating: number;
  totalReviews: number;
  completedBookings: number;
  isVerified: boolean;
  isAvailable: boolean;
  introduction?: string;
  serviceTypes?: Array<{ name: string; icon?: string }>;
  user: {
    id: string;
    profile?: {
      fullName: string;
      displayName?: string;
      avatarUrl?: string;
      coverPhotoUrl?: string;
      bio?: string;
      city?: string;
      district?: string;
      photos?: string[];
      interests?: Array<{ name: string }>;
      talents?: Array<{ name: string }>;
    };
  };
}

async function getPartner(id: string): Promise<PartnerData | null> {
  try {
    const res = await fetch(`${API_BASE_URL}/partners/${id}`, {
      next: { revalidate: 60 }, // Cache for 60 seconds
    });
    if (!res.ok) return null;
    const json = await res.json();
    return json.data || json;
  } catch {
    return null;
  }
}

function buildImageUrl(url?: string | null): string {
  if (!url) return "";
  if (url.startsWith("http")) return url;
  const base = API_BASE_URL.replace("/api", "");
  return `${base}${url}`;
}

type Props = {
  params: Promise<{ id: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const partner = await getPartner(id);

  if (!partner) {
    return {
      title: "Không tìm thấy hồ sơ - Mate Social",
      description: "Hồ sơ partner không tồn tại hoặc đã bị xóa.",
    };
  }

  const name =
    partner.user?.profile?.displayName ||
    partner.user?.profile?.fullName ||
    "Partner";
  const bio = partner.user?.profile?.bio || partner.introduction || "";
  const avatarUrl = buildImageUrl(partner.user?.profile?.avatarUrl);
  const location = [
    partner.user?.profile?.district,
    partner.user?.profile?.city,
  ]
    .filter(Boolean)
    .join(", ");

  const description = bio
    ? `${bio.substring(0, 150)}...`
    : `${name}${location ? ` - ${location}` : ""} | ⭐ ${partner.averageRating?.toFixed(1) || "0.0"} (${partner.totalReviews || 0} đánh giá) | Mate Social`;

  return {
    title: `${name} - Mate Social`,
    description,
    openGraph: {
      title: `${name} - Mate Social`,
      description,
      images: avatarUrl ? [{ url: avatarUrl, width: 400, height: 400 }] : [],
      type: "profile",
      siteName: "Mate Social",
    },
    twitter: {
      card: "summary",
      title: `${name} - Mate Social`,
      description,
      images: avatarUrl ? [avatarUrl] : [],
    },
  };
}

export default async function PartnerPage({ params }: Props) {
  const { id } = await params;
  const partner = await getPartner(id);

  if (!partner) {
    notFound();
  }

  const name =
    partner.user?.profile?.displayName ||
    partner.user?.profile?.fullName ||
    "Partner";
  const avatarUrl = buildImageUrl(partner.user?.profile?.avatarUrl);
  const coverUrl = buildImageUrl(partner.user?.profile?.coverPhotoUrl);
  const bio = partner.user?.profile?.bio || partner.introduction || "";
  const location = [
    partner.user?.profile?.district,
    partner.user?.profile?.city,
  ]
    .filter(Boolean)
    .join(", ");
  const gallery = (partner.user?.profile?.photos || [])
    .map(buildImageUrl)
    .filter(Boolean);
  const services = (partner.serviceTypes || []).map(
    (s: { name: string; icon?: string } | string) =>
      typeof s === "string" ? s : s.name
  ) as string[];
  const interests = (partner.user?.profile?.interests || []).map(
    (i: { name: string } | string) => (typeof i === "string" ? i : i.name)
  );
  const talents = (partner.user?.profile?.talents || []).map(
    (t: { name: string } | string) => (typeof t === "string" ? t : t.name)
  );

  return (
    <PartnerProfileView
      partnerId={id}
      name={name}
      avatarUrl={avatarUrl}
      coverUrl={coverUrl}
      bio={bio}
      location={location}
      rating={partner.averageRating || 0}
      reviewCount={partner.totalReviews || 0}
      completedBookings={partner.completedBookings || 0}
      hourlyRate={partner.hourlyRate || 0}
      isVerified={partner.isVerified}
      isAvailable={partner.isAvailable}
      gallery={gallery}
      services={services}
      interests={interests}
      talents={talents}
    />
  );
}
