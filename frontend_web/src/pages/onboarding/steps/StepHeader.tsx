interface StepHeaderProps {
  emoji: string
  title: string
  subtitle: string
}

/** Onboarding adımları için ortalanmış başlık bloğu. */
export default function StepHeader({ emoji, title, subtitle }: StepHeaderProps) {
  return (
    <div className="flex flex-col items-center text-center mb-12">
      <span className="text-7xl mb-4">{emoji}</span>
      <h2 className="text-4xl sm:text-5xl font-extrabold text-gray-900 leading-tight">
        {title}
      </h2>
      <p className="text-xl text-gray-500 mt-3">{subtitle}</p>
    </div>
  )
}
